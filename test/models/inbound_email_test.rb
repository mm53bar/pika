require "test_helper"

class InboundEmailTest < ActiveSupport::TestCase
  test "adding items creates owned gear linked to the email and marks it handled" do
    email = inbound_emails(:waiting_order)
    socks = email.proposal.last

    created = email.add_items!([ socks ])

    item = created.sole
    assert_equal "Example Wool Socks", item.name
    assert_equal "owned", item.status
    assert_equal Date.new(2026, 9, 19), item.purchased_on
    assert_equal email, item.inbound_email
    assert_equal "Medium\nBought 2.\nBought from Example Outfitters, order EX-1.", item.notes
    assert_equal "added", email.reload.status
    assert_equal [ item.id ], email.created_item_ids
  end

  test "an existing item is found regardless of case" do
    email = inbound_emails(:waiting_order)

    assert_equal items(:tent), email.existing_item_for({ "name" => "example TENT", "manufacturer" => "example co" })
    assert_nil email.existing_item_for({ "name" => "Example Tent", "manufacturer" => "Someone Else" })
  end

  test "claimable only once the LLM has confirmed, a human has handled it, or a known retailer sent it" do
    assert inbound_emails(:waiting_order).claimable?
    assert inbound_emails(:handled).claimable?
    assert_not inbound_emails(:unreadable).claimable?

    email = inbound_emails(:unreadable)
    email.update!(signals: [ "retailer:example-outfitters.test" ])
    assert email.claimable?
  end

  test "not_gear is never claimable" do
    email = inbound_emails(:waiting_order)
    email.apply_triage!({ gear_purchase: false, reason: "A ferry booking." })

    assert_equal "not_gear", email.status
    assert_not email.claimable?
  end

  test "deleting an email keeps the gear that came from it" do
    email = inbound_emails(:waiting_order)
    item = email.add_items!([ email.proposal.last ]).sole

    email.destroy!

    assert_nil item.reload.inbound_email
  end
end
