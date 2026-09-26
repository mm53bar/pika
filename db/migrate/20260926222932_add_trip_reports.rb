class AddTripReports < ActiveRecord::Migration[8.1]
  def change
    add_column :trips, :report, :text
    add_column :trips, :worked_well, :text
    add_column :trips, :didnt_work, :text
    add_column :trips, :reported_on, :date
    add_column :trip_items, :rating, :integer
    add_column :trip_items, :review, :text
  end
end
