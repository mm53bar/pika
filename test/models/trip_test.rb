require "test_helper"

class TripTest < ActiveSupport::TestCase
  test "nights come from the dates" do
    assert_equal 2, trips(:ridge_loop).nights
    assert_nil trips(:undated).nights
  end

  test "a trip cannot end before it starts" do
    trip = Trip.new(name: "Backwards", starts_on: Date.new(2026, 7, 10), ends_on: Date.new(2026, 7, 9))

    assert_not trip.valid?
    assert trip.errors.key?(:ends_on)
  end

  test "weight puts worn footwear in worn, not base" do
    weight = trips(:ridge_loop).weight

    assert_equal 870, weight.base_grams
    assert_equal 700, weight.worn_grams
  end

  test "packing from a kit copies its lines and records the kit" do
    trip = trips(:undated)

    added = trip.pack_from!(kits(:summer_overnight))

    assert_equal 4, added
    assert_equal kits(:summer_overnight), trip.reload.kit
    assert_equal [ "Example Fuel", "Example Quilt", "Example Stove", "Example Tent" ],
                 trip.items.map(&:name).sort
  end

  test "packing from a kit leaves lines already on the trip alone" do
    trip = trips(:ridge_loop)
    trip_items(:ridge_tent).update!(quantity: 2, notes: "spare")

    added = trip.pack_from!(kits(:summer_overnight))

    assert_equal 3, added
    tent_line = trip.trip_items.find_by(item: items(:tent))
    assert_equal 2, tent_line.quantity
    assert_equal "spare", tent_line.notes
  end

  test "meal totals multiply by quantity" do
    assert_equal 1600, trips(:ridge_loop).meal_calories
    assert_equal 360, trips(:ridge_loop).meal_weight_grams
  end
end
