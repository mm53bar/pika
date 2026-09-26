require "test_helper"

class GearTriagerTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(answer) = @answer = answer
    def configured? = true
    def complete_json(**) = @answer
  end

  def triage(answer)
    GearTriager.new(inbound_emails(:waiting_order), client: FakeClient.new(answer), inventory: [ items(:tent), items(:quilt) ]).triage
  end

  test "normalises a purchase" do
    result = triage({
      "gear_purchase" => true, "retailer" => "Example Outfitters", "order_number" => 42, "ordered_on" => "2026-09-19",
      "items" => [ { "name" => " Example Tarp ", "manufacturer" => "Example Co", "category" => "Shelter", "quantity" => "2",
                     "weight_grams" => 300, "weight_source" => "published", "worn" => false, "consumable" => false } ],
      "reason" => "An order."
    })

    assert result[:gear_purchase]
    assert_equal "42", result[:order_number]
    assert_equal Date.new(2026, 9, 19), result[:ordered_on]
    line = result[:items].first
    assert_equal "Example Tarp", line["name"]
    assert_equal 2, line["quantity"]
    assert_equal 300, line["weight_grams"]
  end

  test "a weight without a recognised source is dropped rather than trusted" do
    result = triage({ "gear_purchase" => true, "items" => [ { "name" => "Example Stove", "weight_grams" => 80, "weight_source" => "guess" } ] })

    assert_nil result[:items].first["weight_grams"]
    assert_nil result[:items].first["weight_source"]
  end

  test "missing fields get safe defaults" do
    line = triage({ "gear_purchase" => true, "items" => [ { "name" => "Example Thing", "quantity" => 0 } ] })[:items].first

    assert_equal "Misc", line["category"]
    assert_equal 1, line["quantity"]
    assert_equal false, line["worn"]
    assert_equal false, line["consumable"]
  end

  test "not a gear purchase comes back with no items" do
    result = triage({ "gear_purchase" => false, "items" => [ { "name" => "Ferry ticket" } ], "reason" => "A ferry booking." })

    assert_not result[:gear_purchase]
    assert_empty result[:items]
  end

  test "a purchase with no usable lines is not treated as one" do
    assert_not triage({ "gear_purchase" => true, "items" => [ { "name" => "" } ] })[:gear_purchase]
  end

  test "an existing item id is kept only when it is in the inventory it was given" do
    lines = triage({ "gear_purchase" => true, "items" => [
      { "name" => "Example Tent", "existing_item_id" => items(:tent).id },
      { "name" => "Example Pack", "existing_item_id" => items(:wishlist_pack).id },
      { "name" => "Example Thing", "existing_item_id" => "nonsense" }
    ] })[:items]

    assert_equal [ items(:tent).id, nil, nil ], lines.map { |line| line["existing_item_id"] }
  end

  test "a shortened maker takes the inventory's spelling when only one fits" do
    line = triage({ "gear_purchase" => true, "items" => [ { "name" => "Example Tarp", "manufacturer" => "example" } ] })[:items].first

    assert_equal "Example Co", line["manufacturer"]
  end

  test "an unrelated maker is left as the model wrote it" do
    line = triage({ "gear_purchase" => true, "items" => [ { "name" => "Example Tarp", "manufacturer" => "Other Brand" } ] })[:items].first

    assert_equal "Other Brand", line["manufacturer"]
  end

  test "the prompt carries the inventory with ids" do
    client = Class.new(FakeClient) { attr_reader :user; def complete_json(user:, **) = (@user = user) && nil }.new(nil)
    GearTriager.new(inbound_emails(:waiting_order), client: client, inventory: [ items(:tent) ]).triage

    assert_includes client.user, "- id=#{items(:tent).id} Example Co | Example Tent | Shelter | owned"
  end

  test "an unusable answer is nil" do
    assert_nil triage(nil)
    assert_nil triage({ "items" => [] })
  end
end
