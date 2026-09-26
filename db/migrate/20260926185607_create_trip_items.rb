class CreateTripItems < ActiveRecord::Migration[8.1]
  def change
    create_table :trip_items do |t|
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.references :item, null: false, foreign_key: { on_delete: :cascade }
      t.integer :quantity, null: false, default: 1
      t.boolean :worn, null: false, default: false
      t.integer :weight_grams_override
      t.text :notes

      t.timestamps
    end
    add_index :trip_items, [ :trip_id, :item_id ], unique: true
  end
end
