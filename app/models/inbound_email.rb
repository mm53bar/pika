# A message from the shared inbox that looked like a gear purchase. The LLM
# reads it (GearTriager); if it is one, Pika claims it and it waits in the Inbox
# until a human adds its items to the inventory or ignores it. If the LLM says it
# is not a gear purchase it becomes `not_gear` and is left in the shared inbox
# for whichever app it does belong to.
class InboundEmail < ApplicationRecord
  STATUSES = %w[ received added ignored not_gear ].freeze

  # A single failed read is far more often the LLM being briefly unreachable
  # than an email that can't be read, so triage is retried on later passes.
  MAX_TRIAGE_ATTEMPTS = 3

  has_many :items, dependent: :nullify

  validates :message_id, presence: true, uniqueness: true
  validates :received_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(received_at: :desc) }
  scope :awaiting_review, -> { where(status: "received").where("claimed = ? OR triage_attempts >= ?", true, MAX_TRIAGE_ATTEMPTS) }

  def triaged? = !proposed_items.nil?

  def triage_exhausted? = triage_attempts >= MAX_TRIAGE_ATTEMPTS

  def retailer_matched? = Array(signals).any? { |signal| signal.start_with?("retailer:") }

  def proposal = Array(proposed_items).select { |line| line.is_a?(Hash) }

  # Pika moves a message out of the shared inbox only once it knows the message
  # is its own: the LLM said so, a human already handled it, or the LLM never
  # managed a read but a known retailer sent it.
  def claimable?
    return false if status == "not_gear"

    status != "received" || proposal.any? || (triage_exhausted? && retailer_matched?)
  end

  def apply_triage!(result)
    if result[:gear_purchase]
      update!(proposed_items: result[:items], retailer: result[:retailer], order_number: result[:order_number],
              ordered_on: result[:ordered_on], reason: result[:reason])
    else
      update!(status: "not_gear", proposed_items: [], reason: result[:reason])
    end
  end

  def record_triage_attempt! = increment!(:triage_attempts)

  def retry_triage! = update!(triage_attempts: 0, proposed_items: nil, status: "received")

  # An inventory item with the same name and maker, if there is one. Matching is
  # case-insensitive because order emails and hand-typed names rarely agree on it.
  def existing_item_for(line)
    Item.where("lower(name) = ?", line["name"].to_s.downcase)
        .find { |item| item.manufacturer.to_s.casecmp?(line["manufacturer"].to_s) }
  end

  # Creates one owned item per line and marks this email handled. An order line
  # for several of something becomes one item; the count goes in its notes.
  def add_items!(lines = proposal)
    transaction do
      created = lines.map { |line| Item.create!(item_attributes(line)) }
      update!(status: "added", created_item_ids: created.map(&:id))
      created
    end
  end

  def ignore! = update!(status: "ignored")

  private

  def item_attributes(line)
    quantity = line["quantity"].to_i
    {
      name: line["name"], manufacturer: line["manufacturer"].presence, category: line["category"].presence || "Misc",
      weight_grams: line["weight_grams"].presence, worn: ActiveModel::Type::Boolean.new.cast(line["worn"]) || false,
      consumable: ActiveModel::Type::Boolean.new.cast(line["consumable"]) || false,
      status: "owned", purchased_on: ordered_on || received_at.to_date, inbound_email: self,
      notes: [ line["notes"].presence, ("Bought #{quantity}." if quantity > 1), purchase_note ].compact.join("\n")
    }
  end

  def purchase_note
    parts = [ ("from #{retailer}" if retailer.present?), ("order #{order_number}" if order_number.present?) ].compact
    "Bought #{parts.join(", ")}." if parts.any?
  end
end
