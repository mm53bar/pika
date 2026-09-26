# Reads a captured email with the LLM: is it a gear purchase, and if so, which
# products were bought? The answer is what decides whether Pika claims the
# message (see EmailIntakeJob), and its items become a proposal a human reviews
# before anything reaches the inventory.
#
# Returns a normalised hash, or nil when the model answered with something
# unusable. Raises LlmClient::Unavailable when it could not be reached.
class GearTriager
  SYSTEM = <<~PROMPT.freeze
    You read one email that may be an order confirmation, receipt or shipping notice for
    backpacking or outdoor gear. It is usually FORWARDED, so the retailer's own headers are in
    the body, not the From line.

    Return ONLY JSON:
    {"gear_purchase": true|false,
     "retailer": <store name or null>,
     "order_number": <string or null>,
     "ordered_on": <ISO date or null>,
     "items": [{"name", "manufacturer", "category", "quantity", "weight_grams",
                "weight_source", "worn", "consumable", "notes"}],
     "reason": "one sentence"}

    Rules:
    - gear_purchase is false for anything that is not a purchase of physical gear: travel
      bookings, bills, subscriptions, services, newsletters, marketing. Then items is [].
    - One entry per product line actually bought in this order. Skip shipping, tax, discounts,
      gift cards, fees, and anything under "you might also like" or similar recommendations.
    - manufacturer is the brand (null if unknown). name is the rest of the product title with
      ONLY the brand removed: keep the model or product-line name. "Acme Ridgeline 2 Tent" is
      manufacturer "Acme", name "Ridgeline 2 Tent" — never just "Tent". Size, colour or
      capacity go in notes, not in name.
    - category: choose from EXISTING CATEGORIES when one fits; otherwise a short new one.
    - quantity: integer, as ordered.
    - weight_grams: an integer only if the email explicitly lists the item's weight, such as
      "Weight: 410 g" (weight_source "email"), or you are confident of the manufacturer's
      published weight for that exact product and size (weight_source "published").
      Otherwise null, with weight_source null. Never guess. A number that is part of a
      product's name or size — "230g fuel", "1L bottle", "55L pack", "20F quilt" — is NOT its
      weight: put it in notes.
    - consumable: true only for things used up on a trip (fuel, food, water treatment
      chemicals, fire starters). Containers, bottles, filters and food bags are false.
    - worn: true only for shoes and boots. Everything else, including socks, false.
    - notes: size, colour, capacity or variant from the line, else null.
    JSON only.
  PROMPT

  WEIGHT_SOURCES = %w[ email published ].freeze

  def initialize(email, client: LlmClient.from_env, categories: Item.categories)
    @email = email
    @client = client
    @categories = categories
  end

  def available? = @client.configured?

  def triage
    data = @client.complete_json(system: SYSTEM, user: user_prompt)
    return nil unless data.is_a?(Hash) && [ true, false ].include?(data["gear_purchase"])

    items = data["gear_purchase"] ? normalize_items(data["items"]) : []
    {
      gear_purchase: data["gear_purchase"] && items.any?,
      retailer: data["retailer"].presence,
      order_number: data["order_number"].presence&.to_s,
      ordered_on: parse_date(data["ordered_on"]),
      items: items,
      reason: data["reason"].presence
    }
  end

  private

  def user_prompt
    body = @email.body.to_s[0, 8000]
    "EXISTING CATEGORIES: #{@categories.join(", ").presence || "(none yet)"}\n\n" \
      "EMAIL:\nSubject: #{@email.subject}\nFrom: #{@email.from_address}\n\n#{body}"
  end

  def normalize_items(items)
    Array(items).filter_map do |raw|
      next unless raw.is_a?(Hash) && raw["name"].present?

      source = WEIGHT_SOURCES.include?(raw["weight_source"]) ? raw["weight_source"] : nil
      grams = Integer(raw["weight_grams"], exception: false) if source
      {
        "name" => raw["name"].to_s.strip,
        "manufacturer" => raw["manufacturer"].presence&.to_s&.strip,
        "category" => raw["category"].presence&.to_s&.strip || "Misc",
        "quantity" => [ Integer(raw["quantity"], exception: false) || 1, 1 ].max,
        "weight_grams" => grams&.positive? ? grams : nil,
        "weight_source" => grams&.positive? ? source : nil,
        "worn" => raw["worn"] == true,
        "consumable" => raw["consumable"] == true,
        "notes" => raw["notes"].presence&.to_s&.strip
      }
    end
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
