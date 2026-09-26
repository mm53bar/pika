json.partial! "kits/kit", kit: @kit
json.weight @kit.weight.as_json
json.kit_items @kit.kit_items, partial: "kit_items/kit_item", as: :kit_item
