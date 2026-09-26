require "test_helper"

class PackWeightTest < ActiveSupport::TestCase
  Line = Data.define(:line_weight_grams, :worn, :consumable, :category) do
    def worn? = worn
    def consumable? = consumable
  end

  test "splits lines into base, worn and consumables" do
    weight = PackWeight.new([
      Line.new(870, false, false, "Shelter"),
      Line.new(700, true, false, "Footwear"),
      Line.new(200, false, true, "Fuel")
    ])

    assert_equal 870, weight.base_grams
    assert_equal 700, weight.worn_grams
    assert_equal 200, weight.consumable_grams
    assert_equal 1770, weight.total_grams
  end

  test "a consumable that is worn counts as worn" do
    weight = PackWeight.new([ Line.new(100, true, true, "Food") ])

    assert_equal 100, weight.worn_grams
    assert_equal 0, weight.consumable_grams
  end

  test "totals each category, sorted by name" do
    weight = PackWeight.new([
      Line.new(60, false, false, "Water"),
      Line.new(5, false, true, "Water"),
      Line.new(50, false, false, "Kitchen")
    ])

    assert_equal({ "Kitchen" => 50, "Water" => 65 }, weight.by_category)
  end

  test "JSON keeps fractional grams exact and whole grams as integers" do
    weight = PackWeight.new([ Line.new(BigDecimal("2.5"), false, true, "Water"), Line.new(870, false, false, "Shelter") ])

    assert_equal 2.5, weight.as_json[:consumable_grams]
    assert_kind_of Float, weight.as_json[:consumable_grams]
    assert_kind_of Integer, weight.as_json[:base_grams]
  end
end
