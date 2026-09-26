json.extract! kit_item, :id, :kit_id, :item_id, :quantity, :worn, :notes
json.name kit_item.item.name
json.category kit_item.category
json.consumable kit_item.consumable?
json.line_weight_grams PackWeight.json_grams(kit_item.line_weight_grams)
