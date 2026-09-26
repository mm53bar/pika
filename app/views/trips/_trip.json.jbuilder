json.extract! trip, :id, :name, :destination, :trail, :starts_on, :ends_on, :season, :terrain,
              :kit_id, :notes, :created_at, :updated_at
json.nights trip.nights
json.url trip_url(trip, format: :json)
