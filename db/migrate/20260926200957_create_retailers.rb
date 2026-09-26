class CreateRetailers < ActiveRecord::Migration[8.1]
  def change
    create_table :retailers do |t|
      t.string :value, null: false
      t.string :name
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :retailers, :value, unique: true
  end
end
