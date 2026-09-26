json.extract! meal, :id, :name, :brand, :meal_type, :calories, :weight_grams, :rating, :would_buy_again,
              :notes, :created_at, :updated_at
json.calories_per_100g meal.calories_per_100g
json.url meal_url(meal, format: :json)
