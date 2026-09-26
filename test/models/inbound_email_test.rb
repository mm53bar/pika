require "test_helper"

class InboundEmailTest < ActiveSupport::TestCase
  test "adding items creates owned gear linked to the email and marks it handled" do
    email = inbound_emails(:waiting_order)
    socks = email.proposal.last

    created = email.review!([ socks.merge("action" => "add") ])

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

  test "the default review records a purchase on a match and adds the rest" do
    email = inbound_emails(:waiting_order)

    assert_equal [ [ "link", items(:tent).id ], [ "add", nil ] ], email.default_review.map { |line| [ line["action"], line["item_id"] ] }
  end

  test "recording a purchase on an existing item adds no item and notes the order" do
    email = inbound_emails(:waiting_order)

    assert_no_difference -> { Item.count } do
      email.review!([ email.proposal.first.merge("action" => "link", "item_id" => items(:tent).id) ])
    end

    tent = items(:tent).reload
    assert_equal Date.new(2026, 9, 19), tent.purchased_on
    assert_equal email, tent.inbound_email
    assert_includes tent.notes, "Bought from Example Outfitters, order EX-1."
    assert_empty email.reload.created_item_ids
  end

  test "an earlier purchase date and order email are kept" do
    items(:tent).update!(purchased_on: Date.new(2020, 5, 1))
    email = inbound_emails(:waiting_order)

    email.review!([ { "action" => "link", "item_id" => items(:tent).id } ])

    assert_equal Date.new(2020, 5, 1), items(:tent).reload.purchased_on
  end

  test "buying a wishlist item makes it owned" do
    email = inbound_emails(:waiting_order)

    email.review!([ { "action" => "link", "item_id" => items(:wishlist_pack).id } ])

    assert_equal "owned", items(:wishlist_pack).reload.status
  end

  test "reviewing with every line skipped is refused and changes nothing" do
    email = inbound_emails(:waiting_order)

    assert_raises(ArgumentError) { email.review!(email.proposal.map { |line| line.merge("action" => "skip") }) }
    assert_equal "received", email.reload.status
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
    item = email.review!([ email.proposal.last.merge("action" => "add") ]).sole

    email.destroy!

    assert_nil item.reload.inbound_email
  end
end
