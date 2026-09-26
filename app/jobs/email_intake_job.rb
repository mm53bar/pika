# Reads the shared mailbox, captures what looks like a gear purchase, has the
# LLM confirm it, and only then moves it into Pika's own folder. Anything the
# LLM says is not a gear purchase is left in the shared inbox for whichever app
# it does belong to. See docs/adr/20260926-purchase-intake-from-a-shared-mailbox.md.
#
# Scheduled from config/recurring.yml. Dedup is by Message-ID. Not configured (no
# IMAP env) → does nothing, keeping dev and CI quiet.
class EmailIntakeJob < ApplicationJob
  queue_as :default

  # llm: injectable so tests can drive the unreachable and unusable cases.
  def perform(mailbox: ImapMailbox.from_env, llm: LlmClient.from_env)
    return unless mailbox.configured?

    @llm = llm
    mailbox.open do |session|
      session.each_message { |message| handle(session, message) }
    end
  end

  private

  # One bad message must not strand the rest of the batch behind it.
  def handle(session, message)
    inbound = InboundEmail.find_by(message_id: key(message)) || capture(message)
    return if inbound.nil? || inbound.status == "not_gear"

    triage(inbound) unless inbound.triaged? || inbound.triage_exhausted?
    claim(session, message, inbound) if inbound.claimable?
  rescue StandardError => e
    Rails.logger.error("EmailIntakeJob: uid=#{message.uid} #{e.class}: #{e.message}")
  end

  def key(message) = message.message_id.presence || "imap-#{message.uid}"

  def capture(message)
    result = PurchaseEmailClassifier.new(from: message.from, subject: message.subject, body: message.body).result
    return unless result.purchase?

    InboundEmail.create!(
      message_id: key(message), from_address: message.from, subject: message.subject, body: message.body,
      received_at: message.received_at, score: result.score, signals: result.signals
    )
  end

  def triage(inbound)
    triager = GearTriager.new(inbound, client: @llm)
    return unless triager.available?

    result = triager.triage
    result ? inbound.apply_triage!(result) : inbound.record_triage_attempt!
  rescue LlmClient::Unavailable => e
    Rails.logger.warn("EmailIntakeJob: triage unavailable for ##{inbound.id}: #{e.message}")
    inbound.record_triage_attempt!
  end

  # Capture happens before the move: if storing had failed, the message would
  # still be in the shared inbox for the next run rather than gone from it.
  def claim(session, message, inbound)
    session.archive!(message)
    inbound.update!(claimed: true)
  end
end
