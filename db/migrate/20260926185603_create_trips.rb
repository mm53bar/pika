class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.string :name, null: false
      t.string :destination
      t.string :trail
      t.date :starts_on
      t.date :ends_on
      t.string :season
      t.string :terrain
      t.references :kit, foreign_key: { on_delete: :nullify }
      t.text :notes

      t.timestamps
    end
  end
end
