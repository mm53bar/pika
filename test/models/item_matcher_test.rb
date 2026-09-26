require "test_helper"

class ItemMatcherTest < ActiveSupport::TestCase
  def match(line) = ItemMatcher.new.match(line)

  test "the LLM's pick wins when it exists" do
    assert_equal items(:quilt), match({ "name" => "Something Else", "existing_item_id" => items(:quilt).id })
  end

  test "an LLM pick that isn't an active item falls through to the other tests" do
    assert_equal items(:tent), match({ "name" => "Example Tent", "manufacturer" => "Example Co", "existing_item_id" => items(:retired_mat).id })
  end

  test "the same name and maker, ignoring case" do
    assert_equal items(:tent), match({ "name" => "example TENT", "manufacturer" => "example co" })
  end

  test "the same words, however the email split maker from name" do
    items(:tent).update!(name: "Example Ridgeline 2 (Green)")

    assert_equal items(:tent), match({ "manufacturer" => "Example Co", "name" => "Ridgeline 2" })
    assert_equal items(:tent), match({ "manufacturer" => "Ridgeline", "name" => "2" })
  end

  test "a one-word line matches nothing by words" do
    assert_nil match({ "name" => "Tent" })
  end

  test "words that fit several items match none of them" do
    Item.create!(name: "Example Quilt Liner", category: "Sleep System")

    assert_nil match({ "name" => "Quilt Example" })
  end

  test "a different product from the same maker is not a match" do
    assert_nil match({ "manufacturer" => "Example Co", "name" => "Footprint" })
  end
end
