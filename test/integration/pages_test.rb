require "test_helper"

class PagesTest < ActionDispatch::IntegrationTest
  test "the gear page shows owned gear by category and hides the rest" do
    get root_path

    assert_response :success
    assert_select "h2", "Shelter"
    assert_select "a", "Example Tent"
    assert_select "a", text: "Example Wishlist Pack", count: 0
    assert_select "a", text: "Example Retired Mat", count: 0
  end

  # curl and most agents send Accept: */*, for which Rails renders HTML but
  # request.format.html? is false. Pages must branch on JSON, not on HTML.
  test "pages render for a client that accepts anything" do
    get root_path, headers: { "Accept" => "*/*" }
    assert_response :success
    assert_select "a", text: "Example Wishlist Pack", count: 0

    get inbound_emails_path, headers: { "Accept" => "*/*" }
    assert_response :success
    assert_select "h1", "Inbox"
  end

  test "the wishlist and retired filters" do
    get items_path(status: "wishlist")
    assert_select "a", "Example Wishlist Pack"

    get items_path(retired: 1)
    assert_select "a", "Example Retired Mat"
  end

  test "every index and show page renders" do
    [
      items_path, item_path(items(:drink_mix)), new_item_path, edit_item_path(items(:tent)),
      trips_path, trip_path(trips(:ridge_loop)), trip_path(trips(:undated)), new_trip_path,
      kits_path, kit_path(kits(:summer_overnight)), new_kit_path,
      meals_path, meal_path(meals(:dal)), new_meal_path,
      reference_lists_path, reference_list_path(reference_lists(:example_ul)), new_reference_list_path
    ].each do |path|
      get path
      assert_response :success, "#{path} did not render"
    end
  end

  test "the trip page shows the weight split and offers only unpacked gear" do
    get trip_path(trips(:ridge_loop))

    assert_select "p", "870 g"
    assert_select "p", "1.57 kg"
    assert_select "#trip_item_item_id option", text: "Example Co Example Tent", count: 0
    assert_select "#trip_item_item_id option", text: "Example Quilt"
    assert_select "#trip_item_item_id option", text: "Example Wishlist Pack", count: 0
  end

  test "packing from a kit through the form" do
    post pack_trip_path(trips(:undated)), params: { kit_id: kits(:summer_overnight).id }

    assert_redirected_to trip_path(trips(:undated))
    follow_redirect!
    assert_select "p", /Packed 4 items from Summer Overnight/
  end

  test "creating an item through the form" do
    post items_path, params: { item: { name: "Sun Hoody", category: "Clothing", weight_grams: 150, status: "owned" } }

    item = Item.find_by!(name: "Sun Hoody")
    assert_redirected_to item_path(item)
  end

  test "an invalid trip re-renders the form" do
    post trips_path, params: { trip: { name: "" } }

    assert_response :unprocessable_entity
    assert_select "li", /Name can't be blank/
  end

  test "deleting a kit keeps the trips that were packed from it" do
    trip = trips(:undated)
    trip.pack_from!(kits(:summer_overnight))

    delete kit_path(kits(:summer_overnight))

    assert_nil trip.reload.kit
    assert_equal 4, trip.trip_items.count
  end
end
