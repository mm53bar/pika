require "test_helper"

class TripItemTest < ActiveSupport::TestCase
  test "a trip weight override beats the item's own weight and ignores quantity" do
    line = trip_items(:ridge_tent)
    line.update!(quantity: 2, weight_grams_override: 1000)

    assert_equal 1000, line.line_weight_grams
  end

  test "without an override the line weighs the item times quantity" do
    line = trip_items(:ridge_tent)
    line.update!(quantity: 2)

    assert_equal 1740, line.line_weight_grams
  end

  test "an item can only be packed once per trip" do
    line = trips(:ridge_loop).trip_items.new(item: items(:tent))

    assert_not line.valid?
    assert line.errors.key?(:item_id)
  end
end
