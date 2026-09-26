class CreateKitItems < ActiveRecord::Migration[8.1]
  def change
    create_table :kit_items do |t|
      t.references :kit, null: false, foreign_key: { on_delete: :cascade }
      t.references :item, null: false, foreign_key: { on_delete: :cascade }
      t.integer :quantity, null: false, default: 1
      t.boolean :worn, null: false, default: false
      t.text :notes

      t.timestamps
    end
    add_index :kit_items, [ :kit_id, :item_id ], unique: true
  end
end
