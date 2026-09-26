class CreateInboundEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :inbound_emails do |t|
      t.string :message_id, null: false
      t.string :from_address
      t.string :subject
      t.text :body
      t.datetime :received_at, null: false
      t.integer :score
      t.json :signals
      t.string :status, null: false, default: "received"
      t.boolean :claimed, null: false, default: false
      t.integer :triage_attempts, null: false, default: 0
      t.json :proposed_items
      t.string :retailer
      t.string :order_number
      t.date :ordered_on
      t.string :reason
      t.json :created_item_ids

      t.timestamps
    end
    add_index :inbound_emails, :message_id, unique: true
    add_index :inbound_emails, :status
  end
end
