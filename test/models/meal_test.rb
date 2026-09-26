require "test_helper"

class MealTest < ActiveSupport::TestCase
  test "calorie density per 100 g" do
    assert_equal 444, meals(:dal).calories_per_100g
  end

  test "calorie density is unknown without a weight" do
    assert_nil Meal.new(name: "Unweighed", calories: 300).calories_per_100g
  end

  test "rating runs one to five" do
    meal = meals(:dal)
    meal.rating = 6

    assert_not meal.valid?
  end
end
