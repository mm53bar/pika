json.partial! "reference_lists/reference_list", reference_list: @reference_list
json.weight @reference_list.weight.as_json
json.reference_items @reference_list.reference_items, partial: "reference_items/reference_item", as: :reference_item
