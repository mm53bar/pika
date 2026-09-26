require "test_helper"

class TripReportPagesTest < ActionDispatch::IntegrationTest
  test "a past trip leads with the report and folds the packing list away" do
    travel_to(Date.new(2026, 8, 1)) do
      get trip_path(trips(:ridge_loop))

      assert_response :success
      assert_select "h2", "Trip report"
      assert_select "select#lines_#{trip_items(:ridge_tent).id}_rating"
      assert_select "details summary", "Edit the packing list"
      assert_select "details #trip_item_item_id"
    end
  end

  test "an upcoming trip has no report yet" do
    travel_to(Date.new(2026, 7, 1)) do
      get trip_path(trips(:ridge_loop))

      assert_select "h2", text: "Trip report", count: 0
      assert_select "details summary", count: 0
    end
  end

  test "filing a report from the page" do
    tent = trip_items(:ridge_tent)

    travel_to(Date.new(2026, 8, 1)) do
      patch report_trip_path(trips(:ridge_loop)), params: {
        trip: { report: "Great loop.", worked_well: "Tent", didnt_work: "Socks" },
        lines: { tent.id.to_s => { rating: "5", review: "Dry all night" }, trip_items(:ridge_runners).id.to_s => { rating: "", review: "" } }
      }
    end

    assert_redirected_to trip_path(trips(:ridge_loop))
    assert_equal "Great loop.", trips(:ridge_loop).reload.report
    assert_equal 5, tent.reload.rating
    assert_nil trip_items(:ridge_runners).reload.rating
  end

  test "filing a report over JSON, with lines as an array" do
    tent = trip_items(:ridge_tent)

    patch report_trip_path(trips(:ridge_loop), format: :json),
          params: { trip: { report: "Great loop." }, lines: [ { id: tent.id, rating: 4, review: "Fine" } ] }, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal "Great loop.", body["report"]
    assert_equal 4, body["trip_items"].find { |line| line["id"] == tent.id }["rating"]
  end

  test "a bad rating over JSON is refused" do
    patch report_trip_path(trips(:ridge_loop), format: :json),
          params: { lines: [ { id: trip_items(:ridge_tent).id, rating: 9 } ] }, as: :json

    assert_response :unprocessable_entity
  end

  test "the trips list flags past trips without a report" do
    travel_to(Date.new(2026, 8, 1)) do
      get trips_path
      assert_select "li#trip_#{trips(:ridge_loop).id}", text: /report due/

      trips(:ridge_loop).file_report!({ report: "Done." })
      get trips_path
      assert_select "li#trip_#{trips(:ridge_loop).id}", text: /reported/
    end
  end

  test "an item's page shows how it did on each trip" do
    trip_items(:ridge_tent).update!(rating: 4, review: "Dry all night")

    get item_path(items(:tent))

    assert_select "h2", /★ 4.0 average/
    assert_select "li", /Ridge Loop.*★★★★.*Dry all night/m
  end
end
