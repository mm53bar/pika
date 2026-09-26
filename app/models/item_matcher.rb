# Finds the inventory item an order line already is, so buying something Pika
# already has records the purchase instead of creating a second copy.
#
# Three tests, in order: the id the LLM picked (checked to exist), the same name
# and maker, then the same words. The last one compares maker and name together,
# ignoring case, punctuation and bracketed variants, because order emails split
# them unpredictably — "Acme | Ridgeline 2" and "Ridgeline | 2" both describe
# "Acme Ridgeline 2 (Green)". It only counts when exactly one item fits and the
# line has at least two words, so a bare "Tent" matches nothing.
class ItemMatcher
  def initialize(items = Item.active.to_a)
    @items = items
  end

  def match(line)
    by_id(line["existing_item_id"]) || by_name(line) || by_words(line)
  end

  private

  def by_id(id)
    @items.find { |item| item.id == Integer(id, exception: false) } if id.present?
  end

  def by_name(line)
    @items.find do |item|
      item.name.casecmp?(line["name"].to_s) && item.manufacturer.to_s.casecmp?(line["manufacturer"].to_s)
    end
  end

  def by_words(line)
    wanted = words(line["manufacturer"], line["name"])
    return if wanted.size < 2

    fits = @items.select { |item| wanted <= words(item.manufacturer, item.name) }
    fits.first if fits.one?
  end

  def words(*parts)
    text = parts.compact.join(" ").downcase.gsub(/\([^)]*\)/, " ")
    text.scan(/[a-z0-9]+(?:-[a-z0-9]+)*/).to_set
  end
end
