# Splits a set of packed lines into the three weights backpackers compare:
# base (carried, not used up), worn, and consumables. Each line answers
# #line_weight_grams, #worn?, #consumable? and #category.
#
# Worn is checked first, so a consumable carried on the body counts as worn.
class PackWeight
  attr_reader :base_grams, :worn_grams, :consumable_grams, :by_category

  def initialize(lines)
    @base_grams = @worn_grams = @consumable_grams = 0
    @by_category = Hash.new(0)

    lines.each do |line|
      grams = line.line_weight_grams
      @by_category[line.category] += grams

      if line.worn?
        @worn_grams += grams
      elsif line.consumable?
        @consumable_grams += grams
      else
        @base_grams += grams
      end
    end

    @by_category = @by_category.sort.to_h
  end

  # Grams as a JSON number: whole values as integers, fractions kept exact. Rails
  # would otherwise serialise a BigDecimal as a string.
  def self.json_grams(grams)
    return if grams.nil?

    (grams % 1).zero? ? grams.to_i : grams.to_f
  end

  def total_grams = base_grams + worn_grams + consumable_grams

  def as_json(*)
    {
      base_grams: self.class.json_grams(base_grams), worn_grams: self.class.json_grams(worn_grams),
      consumable_grams: self.class.json_grams(consumable_grams), total_grams: self.class.json_grams(total_grams),
      by_category: by_category.transform_values { |grams| self.class.json_grams(grams) }
    }
  end
end
