json.extract! trip, :id, :name, :destination, :trail, :starts_on, :ends_on, :season, :terrain,
              :kit_id, :notes, :created_at, :updated_at
json.extract! trip, :report, :worked_well, :didnt_work, :reported_on
json.nights trip.nights
json.past trip.past?
json.url trip_url(trip, format: :json)
