json.extract! item, :id, :name, :manufacturer, :category, :weight_grams, :measured_weight_grams,
              :unit_label, :status, :worn, :consumable, :retired, :notes, :purchased_on, :inbound_email_id,
              :created_at, :updated_at
json.unit_weight_grams PackWeight.json_grams(item.unit_weight_grams)
json.effective_weight_grams item.effective_weight_grams
json.average_rating item.average_rating
json.url item_url(item, format: :json)
