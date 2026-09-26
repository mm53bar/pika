require "application_system_test_case"

class CategorySelectTest < ApplicationSystemTestCase
  def open_category_select
    find("#item_category + .ts-wrapper .ts-control").click
    find(".ts-dropdown", visible: true)
  end

  def listed_categories = all(".ts-dropdown .option").map(&:text)

  # The bug this component replaced: with a value already chosen, the browser's
  # datalist only ever offered that one value.
  test "opening the picker on an item with a category lists every category" do
    visit edit_item_path(items(:tent))

    open_category_select

    assert_equal Item.categories.sort, listed_categories.sort
  end

  test "typing filters the list" do
    visit new_item_path
    open_category_select

    find(".ts-dropdown .dropdown-input").send_keys("slee")

    assert_selector ".ts-dropdown .option", count: 1
    assert_equal [ "Sleep System" ], listed_categories
  end

  test "choosing an existing category saves it" do
    visit new_item_path
    fill_in "Name", with: "Example Liner"
    open_category_select
    find(".ts-dropdown .option", text: "Kitchen").click
    click_on "Create Item"

    assert_text "Example Liner added."
    assert_equal "Kitchen", Item.find_by!(name: "Example Liner").category
  end

  test "typing a new category creates it" do
    visit new_item_path
    fill_in "Name", with: "Example Bivy"
    open_category_select
    find(".ts-dropdown .dropdown-input").send_keys("Bivy")
    find(".ts-dropdown .create", text: /Bivy/).click
    click_on "Create Item"

    assert_text "Example Bivy added."
    assert_equal "Bivy", Item.find_by!(name: "Example Bivy").category
  end
end
