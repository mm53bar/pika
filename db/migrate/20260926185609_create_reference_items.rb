class CreateReferenceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :reference_items do |t|
      t.references :reference_list, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :manufacturer
      t.string :category, null: false, default: "Misc"
      t.integer :weight_grams
      t.integer :quantity, null: false, default: 1
      t.boolean :worn, null: false, default: false
      t.boolean :consumable, null: false, default: false
      t.text :notes

      t.timestamps
    end
  end
end
