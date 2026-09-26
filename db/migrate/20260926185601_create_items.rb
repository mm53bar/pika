class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.string :manufacturer
      t.string :category, null: false, default: "Misc"
      t.integer :weight_grams
      t.integer :measured_weight_grams
      t.decimal :unit_weight_grams, precision: 8, scale: 2
      t.string :unit_label
      t.string :status, null: false, default: "owned"
      t.boolean :worn, null: false, default: false
      t.boolean :consumable, null: false, default: false
      t.boolean :retired, null: false, default: false
      t.text :notes

      t.timestamps
    end
    add_index :items, :category
  end
end
