require "test_helper"

class EmailIntakeJobTest < ActiveJob::TestCase
  # Stand-in for ImapMailbox (no network), recording what got moved out.
  class FakeMailbox
    attr_reader :archived

    def initialize(messages, configured: true)
      @messages = messages
      @configured = configured
      @archived = []
    end

    def configured? = @configured
    def open = yield self
    def each_message(&block) = @messages.each(&block)
    def archive!(message) = @archived << message.message_id
  end

  # Answers with a fixed reply, or raises Unavailable; counts its calls.
  class FakeLlm
    attr_reader :calls

    def initialize(answer = nil, unavailable: false)
      @answer = answer
      @unavailable = unavailable
      @calls = 0
    end

    def configured? = true

    def complete_json(**)
      @calls += 1
      raise LlmClient::Unavailable, "down" if @unavailable

      @answer
    end
  end

  GEAR = { "gear_purchase" => true, "retailer" => "Example Outfitters", "order_number" => "EX-9",
           "items" => [ { "name" => "Example Quilt 2", "manufacturer" => "Example Co", "category" => "Sleep System", "quantity" => 1 } ],
           "reason" => "An order." }.freeze
  NOT_GEAR = { "gear_purchase" => false, "items" => [], "reason" => "A ferry booking." }.freeze

  def order(id = "o1@x", uid: 1, from: "A Person <person@example.org>")
    msg(id, uid: uid, from: from, subject: "Fwd: Your order is confirmed", body: "Order number EX-9. Subtotal $300. Qty 1.")
  end

  def msg(message_id, from:, subject:, body:, uid: 1)
    ImapMailbox::Message.new(uid: uid, message_id: message_id, references: [], from: from,
                             subject: subject, body: body, received_at: Time.current)
  end

  test "a confirmed gear purchase is captured, proposed and claimed" do
    mailbox = FakeMailbox.new([ order ])

    EmailIntakeJob.perform_now(mailbox: mailbox, llm: FakeLlm.new(GEAR))

    email = InboundEmail.find_by!(message_id: "o1@x")
    assert_equal [ "Example Quilt 2" ], email.proposal.map { |line| line["name"] }
    assert email.claimed?
    assert_equal [ "o1@x" ], mailbox.archived
  end

  test "ordinary mail is neither captured nor moved, and costs no LLM call" do
    mailbox = FakeMailbox.new([ msg("n1@x", from: "friend@example.org", subject: "Hike Saturday?", body: "Meet at 8.") ])
    llm = FakeLlm.new(GEAR)

    assert_no_difference -> { InboundEmail.count } do
      EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm)
    end
    assert_empty mailbox.archived
    assert_equal 0, llm.calls
  end

  test "something the LLM says is not gear is left in the shared inbox for good" do
    mailbox = FakeMailbox.new([ order ])
    llm = FakeLlm.new(NOT_GEAR)

    EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm)
    EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm)

    assert_equal "not_gear", InboundEmail.find_by!(message_id: "o1@x").status
    assert_empty mailbox.archived
    assert_equal 1, llm.calls, "a released message must not be re-read on every pass"
  end

  test "while the LLM is down a message stays in the shared inbox and is retried" do
    mailbox = FakeMailbox.new([ order ])
    llm = FakeLlm.new(unavailable: true)

    3.times { EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm) }
    4.times { EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm) }

    email = InboundEmail.find_by!(message_id: "o1@x")
    assert_equal InboundEmail::MAX_TRIAGE_ATTEMPTS, email.triage_attempts
    assert_equal InboundEmail::MAX_TRIAGE_ATTEMPTS, llm.calls
    assert_empty mailbox.archived
  end

  test "a known retailer's email is claimed once the retries run out, for a human to read" do
    mailbox = FakeMailbox.new([ order(from: "Shop <orders@example-outfitters.test>") ])
    llm = FakeLlm.new(unavailable: true)

    2.times { EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm) }
    assert_empty mailbox.archived

    EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm)
    assert_equal [ "o1@x" ], mailbox.archived
    assert_includes InboundEmail.awaiting_review, InboundEmail.find_by!(message_id: "o1@x")
  end

  test "an unusable answer counts as a failed read" do
    EmailIntakeJob.perform_now(mailbox: FakeMailbox.new([ order ]), llm: FakeLlm.new({ "nonsense" => true }))

    assert_equal 1, InboundEmail.find_by!(message_id: "o1@x").triage_attempts
  end

  test "an already-handled message still in the shared inbox is moved without being read again" do
    handled = inbound_emails(:handled)
    mailbox = FakeMailbox.new([ msg(handled.message_id, from: "x@example.org", subject: handled.subject, body: handled.body) ])
    llm = FakeLlm.new(GEAR)

    assert_no_difference -> { InboundEmail.count } do
      EmailIntakeJob.perform_now(mailbox: mailbox, llm: llm)
    end
    assert_equal [ handled.message_id ], mailbox.archived
    assert_equal 0, llm.calls
  end

  class ExplodingMessage
    def uid = 1
    def message_id = "bad@x"
    def from = "x@example.org"
    def subject = "Your order"
    def body = raise("unreadable")
  end

  test "one unreadable message doesn't strand the rest of the batch" do
    mailbox = FakeMailbox.new([ ExplodingMessage.new, order("o2@x", uid: 2) ])

    EmailIntakeJob.perform_now(mailbox: mailbox, llm: FakeLlm.new(GEAR))

    assert_equal [ "o2@x" ], mailbox.archived
  end

  test "a message with no Message-ID is keyed by its IMAP uid" do
    EmailIntakeJob.perform_now(mailbox: FakeMailbox.new([ order(nil, uid: 77) ]), llm: FakeLlm.new(GEAR))

    assert InboundEmail.exists?(message_id: "imap-77")
  end

  test "does nothing when the mailbox is not configured" do
    llm = FakeLlm.new(GEAR)

    EmailIntakeJob.perform_now(mailbox: FakeMailbox.new([ order ], configured: false), llm: llm)

    assert_not InboundEmail.exists?(message_id: "o1@x")
    assert_equal 0, llm.calls
  end
end
