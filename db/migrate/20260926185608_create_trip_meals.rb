class CreateTripMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :trip_meals do |t|
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.references :meal, null: false, foreign_key: { on_delete: :cascade }
      t.integer :quantity, null: false, default: 1
      t.text :notes

      t.timestamps
    end
  end
end
