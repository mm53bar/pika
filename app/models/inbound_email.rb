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

  # Once a human has added or ignored an email its proposal is history: reading it
  # again would reopen it and let the same order be added twice.
  def retriageable? = status.in?(%w[ received not_gear ])

  def retry_triage! = update!(triage_attempts: 0, proposed_items: nil, status: "received")

  ACTIONS = %w[ add link skip ].freeze

  # The inventory item a proposed line already is, if any (see ItemMatcher).
  def existing_item_for(line) = matcher.match(line)

  # The proposal with each line's default decision: record the purchase on the
  # item it matches, otherwise add it as new.
  def default_review
    proposal.map do |line|
      existing = existing_item_for(line)
      existing ? line.merge("action" => "link", "item_id" => existing.id) : line.merge("action" => "add")
    end
  end

  # Applies a reviewed proposal: each line is added as a new owned item, recorded
  # as a purchase of an existing one, or skipped. An order line for several of
  # something becomes one item; the count goes in its notes. Returns the items
  # touched, and marks this email handled.
  def review!(lines = default_review)
    transaction do
      touched = lines.filter_map do |line|
        case line["action"]
        when "add" then Item.create!(item_attributes(line))
        when "link" then record_purchase_on!(Item.find(line["item_id"]))
        end
      end
      raise ArgumentError, "Nothing selected to add." if touched.empty?

      update!(status: "added", created_item_ids: touched.select(&:previously_new_record?).map(&:id))
      touched
    end
  end

  def ignore! = update!(status: "ignored")

  private

  def matcher = @matcher ||= ItemMatcher.new

  def purchase_date = ordered_on || received_at.to_date

  # Buying something already in the inventory: note when and where, keep any
  # earlier purchase date, and promote a wishlist item to owned.
  def record_purchase_on!(item)
    note = purchase_note
    item.update!(
      purchased_on: item.purchased_on || purchase_date,
      inbound_email: item.inbound_email || self,
      status: "owned",
      notes: note && !item.notes.to_s.include?(note) ? [ item.notes.presence, note ].compact.join("\n") : item.notes
    )
    item
  end

  def item_attributes(line)
    quantity = line["quantity"].to_i
    {
      name: line["name"], manufacturer: line["manufacturer"].presence, category: line["category"].presence || "Misc",
      weight_grams: line["weight_grams"].presence, worn: ActiveModel::Type::Boolean.new.cast(line["worn"]) || false,
      consumable: ActiveModel::Type::Boolean.new.cast(line["consumable"]) || false,
      status: "owned", purchased_on: purchase_date, inbound_email: self,
      notes: [ line["notes"].presence, ("Bought #{quantity}." if quantity > 1), purchase_note ].compact.join("\n")
    }
  end

  def purchase_note
    parts = [ ("from #{retailer}" if retailer.present?), ("order #{order_number}" if order_number.present?) ].compact
    "Bought #{parts.join(", ")}." if parts.any?
  end
end
