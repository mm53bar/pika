json.partial! "trips/trip", trip: @trip
json.weight @trip.weight.as_json
json.trip_items @trip.trip_items, partial: "trip_items/trip_item", as: :trip_item
json.trip_meals @trip.trip_meals, partial: "trip_meals/trip_meal", as: :trip_meal
json.meal_calories @trip.meal_calories
json.meal_weight_grams @trip.meal_weight_grams
