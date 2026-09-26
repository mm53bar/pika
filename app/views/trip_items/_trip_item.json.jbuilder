json.extract! trip_item, :id, :trip_id, :item_id, :quantity, :worn, :weight_grams_override, :notes, :rating, :review
json.name trip_item.item.name
json.category trip_item.category
json.consumable trip_item.consumable?
json.line_weight_grams PackWeight.json_grams(trip_item.line_weight_grams)
