require "test_helper"

class ApiTest < ActionDispatch::IntegrationTest
  test "the item index returns the whole inventory as JSON" do
    get items_path(format: :json)

    assert_response :success
    names = response.parsed_body.map { |item| item["name"] }
    assert_includes names, "Example Wishlist Pack"
    assert_includes names, "Example Retired Mat"
  end

  test "the item index filters by status when asked" do
    get items_path(format: :json, status: "wishlist")

    assert_equal [ "Example Wishlist Pack" ], response.parsed_body.map { |item| item["name"] }
  end

  test "item filters apply only when given, and combine" do
    items(:wishlist_pack).update!(retired: true)

    get items_path(format: :json, retired: 1)
    assert_equal [ "Example Retired Mat", "Example Wishlist Pack" ], response.parsed_body.map { |item| item["name"] }.sort

    get items_path(format: :json, status: "owned", retired: 0)
    names = response.parsed_body.map { |item| item["name"] }
    assert_includes names, "Example Tent"
    assert_not_includes names, "Example Retired Mat"
    assert_not_includes names, "Example Wishlist Pack"
  end

  test "an item round-trips its weights" do
    post items_path(format: :json), params: {
      item: { name: "Wind Shirt", category: "Clothing", weight_grams: 70, measured_weight_grams: 64 }
    }, as: :json

    assert_response :created
    assert_equal 64, response.parsed_body["effective_weight_grams"]
  end

  test "an invalid item comes back with its errors" do
    post items_path(format: :json), params: { item: { name: "" } }, as: :json

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].key?("name")
  end

  test "packing an item takes its worn default unless told otherwise" do
    trip = trips(:undated)

    post trip_trip_items_path(trip, format: :json), params: { trip_item: { item_id: items(:trail_runners).id } }, as: :json
    assert_response :created
    assert response.parsed_body["worn"]

    post trip_trip_items_path(trip, format: :json), params: { trip_item: { item_id: items(:rain_jacket).id, worn: true } }, as: :json
    assert response.parsed_body["worn"]
  end

  # Rails serialises decimals as strings. Grams must reach a caller as numbers it
  # can add up, fractions included.
  test "fractional weights come back as JSON numbers" do
    trip = trips(:undated)
    trip.trip_items.create!(item: items(:drink_mix), quantity: 3)

    get item_path(items(:drink_mix), format: :json)
    assert_equal 2.5, response.parsed_body["unit_weight_grams"]

    get trip_path(trip, format: :json)
    assert_equal 7.5, response.parsed_body["trip_items"].first["line_weight_grams"]
    assert_equal 7.5, response.parsed_body.dig("weight", "consumable_grams")
  end

  test "packing the same item twice is refused" do
    post trip_trip_items_path(trips(:ridge_loop), format: :json), params: { trip_item: { item_id: items(:tent).id } }, as: :json

    assert_response :unprocessable_entity
  end

  test "a line cannot be moved to a different item by update" do
    line = trip_items(:ridge_tent)

    patch trip_item_path(line, format: :json), params: { trip_item: { item_id: items(:quilt).id, quantity: 3 } }, as: :json

    assert_response :success
    assert_equal items(:tent), line.reload.item
    assert_equal 3, line.quantity
  end

  test "a trip shows its lines, meals and weight split" do
    get trip_path(trips(:ridge_loop), format: :json)

    body = response.parsed_body
    assert_equal 2, body["nights"]
    assert_equal 870, body.dig("weight", "base_grams")
    assert_equal 700, body.dig("weight", "worn_grams")
    assert_equal 2, body["trip_items"].size
    assert_equal 1600, body["meal_calories"]
  end

  test "packing a trip from a kit over the API" do
    post pack_trip_path(trips(:undated), format: :json), params: { kit_id: kits(:summer_overnight).id }, as: :json

    assert_response :success
    assert_equal 4, response.parsed_body["trip_items"].size
    assert_equal 200, response.parsed_body.dig("weight", "consumable_grams")
  end

  test "a reference list takes items" do
    post reference_list_reference_items_path(reference_lists(:example_ul), format: :json),
         params: { reference_item: { name: "Cook Pot", category: "Kitchen", weight_grams: 90 } }, as: :json

    assert_response :created
    get reference_list_path(reference_lists(:example_ul), format: :json)
    assert_equal 1270 + 90, response.parsed_body.dig("weight", "base_grams")
  end

  # Forgery protection is off in the test environment, so every other test here
  # would pass even if the API rejected all machine callers. This turns it on and
  # asserts both halves, so the contrast proves it is genuinely active.
  test "the JSON API takes posts with no CSRF token while HTML forms still demand one" do
    with_forgery_protection do
      post items_path(format: :json), params: { item: { name: "Bandana", category: "Clothing" } }, as: :json
      assert_response :created

      post items_path, params: { item: { name: "Bandana", category: "Clothing" } }
      assert_response :unprocessable_entity
    end
  end

  private

  def with_forgery_protection
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
