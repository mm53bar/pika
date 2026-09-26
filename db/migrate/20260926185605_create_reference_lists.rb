class CreateReferenceLists < ActiveRecord::Migration[8.1]
  def change
    create_table :reference_lists do |t|
      t.string :name, null: false
      t.string :author
      t.string :source_url
      t.text :notes

      t.timestamps
    end
  end
end
