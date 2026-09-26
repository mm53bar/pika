class AddPurchaseToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :purchased_on, :date
    add_reference :items, :inbound_email, foreign_key: { on_delete: :nullify }
  end
end
