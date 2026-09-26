require "test_helper"

class TripReportTest < ActiveSupport::TestCase
  test "a trip is past once its last day has gone by" do
    trip = trips(:ridge_loop)

    travel_to(Date.new(2026, 7, 12)) { assert_not trip.past? }
    travel_to(Date.new(2026, 7, 13)) { assert trip.past? }
  end

  test "a trip without dates is never past" do
    travel_to(Date.new(2030, 1, 1)) { assert_not trips(:undated).past? }
  end

  test "a trip with only a start date is past after that day" do
    trip = Trip.new(name: "Day hike", starts_on: Date.new(2026, 7, 10))

    travel_to(Date.new(2026, 7, 11)) { assert trip.past? }
  end

  test "filing a report saves it with the date and rates the packed gear" do
    trip = trips(:ridge_loop)

    travel_to(Date.new(2026, 7, 14)) do
      trip.file_report!({ report: "Windy on the ridge.", worked_well: "The tent.", didnt_work: "Too much food." },
                        { trip_items(:ridge_tent).id.to_s => { "rating" => "5", "review" => "Bombproof in gusts" } })
    end

    trip.reload
    assert_equal "Windy on the ridge.", trip.report
    assert_equal Date.new(2026, 7, 14), trip.reported_on
    assert_equal 5, trip_items(:ridge_tent).reload.rating
    assert_equal "Bombproof in gusts", trip_items(:ridge_tent).review
  end

  test "editing a report keeps the date it was first filed" do
    trip = trips(:ridge_loop)
    travel_to(Date.new(2026, 7, 14)) { trip.file_report!({ report: "First go." }) }
    travel_to(Date.new(2026, 8, 1)) { trip.file_report!({ report: "Second thoughts." }) }

    assert_equal Date.new(2026, 7, 14), trip.reload.reported_on
    assert_equal "Second thoughts.", trip.report
  end

  test "a blank rating clears it" do
    trip_items(:ridge_tent).update!(rating: 3, review: "ok")

    trips(:ridge_loop).file_report!({}, { trip_items(:ridge_tent).id.to_s => { "rating" => "", "review" => "" } })

    assert_nil trip_items(:ridge_tent).reload.rating
    assert_nil trip_items(:ridge_tent).review
  end

  test "lines from another trip are ignored" do
    other = trips(:undated).trip_items.create!(item: items(:quilt))

    trips(:ridge_loop).file_report!({}, { other.id.to_s => { "rating" => "1" } })

    assert_nil other.reload.rating
  end

  test "a rating outside one to five is refused and nothing is saved" do
    trip = trips(:ridge_loop)

    assert_raises(ActiveRecord::RecordInvalid) do
      trip.file_report!({ report: "Nope." }, { trip_items(:ridge_tent).id.to_s => { "rating" => "6" } })
    end
    assert_nil trip.reload.report
  end

  test "an item's history and average come from its trip ratings" do
    trip_items(:ridge_tent).update!(rating: 4, review: "Good")
    trips(:undated).trip_items.create!(item: items(:tent), rating: 2)

    assert_equal 3.0, items(:tent).average_rating
    assert_equal 2, items(:tent).trip_reviews.size
    assert_nil items(:quilt).average_rating
  end
end
