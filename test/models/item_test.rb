require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "a weighed item uses its measured weight over the listed one" do
    assert_equal 870, items(:tent).effective_weight_grams
    assert_equal 600, items(:quilt).effective_weight_grams
  end

  test "weight scales with quantity" do
    assert_equal 1200, items(:quilt).weight_for(2)
  end

  test "a per-unit item weighs its unit weight times the count, fractions included" do
    assert_equal 25, items(:drink_mix).weight_for(10)
    assert_equal 7.5, items(:drink_mix).weight_for(3)
  end

  test "an item with no weight at all is unweighed and counts as zero" do
    item = Item.new(name: "Mystery", category: "Misc")

    assert item.unweighed?
    assert_equal 0, item.weight_for(1)
  end

  test "consumable is its own flag, independent of category" do
    bottle = items(:water_bottle)
    bottle.category = "Food"

    assert_not bottle.consumable?
    assert items(:drink_mix).consumable?
  end

  test "status must be one of the known values" do
    item = items(:quilt)
    item.status = "borrowed"

    assert_not item.valid?
    assert item.errors.of_kind?(:status, :inclusion)
  end

  test "weights cannot be negative" do
    item = Item.new(name: "Negative", category: "Misc", weight_grams: -1)

    assert_not item.valid?
  end
end
