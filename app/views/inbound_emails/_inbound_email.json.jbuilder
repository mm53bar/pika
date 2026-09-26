json.extract! inbound_email, :id, :message_id, :from_address, :subject, :received_at, :status, :claimed,
              :score, :signals, :retailer, :order_number, :ordered_on, :reason, :triage_attempts,
              :created_item_ids, :created_at, :updated_at
json.proposed_items inbound_email.proposal
json.url inbound_email_url(inbound_email, format: :json)
