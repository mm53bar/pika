class CreateMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :meals do |t|
      t.string :name, null: false
      t.string :brand
      t.string :meal_type, null: false, default: "dinner"
      t.integer :calories
      t.integer :weight_grams
      t.integer :rating
      t.boolean :would_buy_again
      t.text :notes

      t.timestamps
    end
  end
end
