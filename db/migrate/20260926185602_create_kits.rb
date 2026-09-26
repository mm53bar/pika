class CreateKits < ActiveRecord::Migration[8.1]
  def change
    create_table :kits do |t|
      t.string :name, null: false
      t.text :description
      t.string :season

      t.timestamps
    end
  end
end
