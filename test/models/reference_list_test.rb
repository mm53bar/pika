require "test_helper"

class ReferenceListTest < ActiveSupport::TestCase
  test "weight counts quantity and splits worn and consumable" do
    weight = reference_lists(:example_ul).weight

    assert_equal 300 + 450 + 500 + (10 * 2), weight.base_grams
    assert_equal 250 * 2, weight.worn_grams
    assert_equal 100, weight.consumable_grams
    assert_equal 500 + (10 * 2), weight.by_category["Pack"]
  end

  test "source URL must be http or https" do
    list = reference_lists(:example_ul)
    list.source_url = "javascript:alert(1)"

    assert_not list.valid?
  end

  test "a valid source URL is safe to link" do
    assert_equal "https://example.com/gear-list", reference_lists(:example_ul).safe_source_url
  end

  test "a source URL written around the validation is not rendered as a link" do
    list = reference_lists(:example_ul)
    list.update_column(:source_url, "javascript:alert(1)")

    assert_nil list.safe_source_url
  end
end
