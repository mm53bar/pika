require "test_helper"

class InboxTest < ActionDispatch::IntegrationTest
  test "the inbox lists what is waiting and the nav counts it" do
    get inbound_emails_path

    assert_response :success
    assert_select "li#inbound_email_#{inbound_emails(:waiting_order).id}"
    assert_select "li#inbound_email_#{inbound_emails(:unreadable).id}", text: /couldn't be read/
    assert_select "header a[href='#{inbound_emails_path}'] span", "2"
  end

  test "reviewing: a line already in the gear defaults to recording the purchase on it" do
    get inbound_email_path(inbound_emails(:waiting_order))

    assert_response :success
    assert_select "input#items_0_action_link[checked]"
    assert_select "label", /Record this purchase on\s+Example Co Example Tent/
    assert_select "input#items_1_action_add[checked]"
    assert_select "input#items_1_action_link", count: 0
  end

  test "saving a review: one line recorded on existing gear, one added with edits" do
    email = inbound_emails(:waiting_order)

    assert_difference -> { Item.count }, 1 do
      post add_items_inbound_email_path(email), params: { items: {
        "0" => { action: "link", item_id: items(:tent).id, name: "Example Tent", manufacturer: "Example Co", category: "Shelter", quantity: "1" },
        "1" => { action: "add", name: "Example Merino Socks", manufacturer: "Example Knits", category: "Clothing",
                 weight_grams: "60", quantity: "2", worn: "0", consumable: "0", notes: "Medium" }
      } }
    end
    assert_equal email, items(:tent).reload.inbound_email

    assert_redirected_to inbound_emails_path
    item = Item.find_by!(name: "Example Merino Socks")
    assert_equal 60, item.weight_grams
    assert_equal "added", email.reload.status
  end

  test "an email is only added once" do
    email = inbound_emails(:waiting_order)
    post add_items_inbound_email_path(email, format: :json), as: :json

    assert_no_difference -> { Item.count } do
      post add_items_inbound_email_path(email, format: :json), as: :json
    end
    assert_response :unprocessable_entity
  end

  test "over JSON, posting nothing takes the default review" do
    assert_difference -> { Item.count }, 1 do
      post add_items_inbound_email_path(inbound_emails(:waiting_order), format: :json), as: :json
    end

    assert_response :created
    assert_equal 1, response.parsed_body["created_item_ids"].size
    assert_equal inbound_emails(:waiting_order), items(:tent).reload.inbound_email
  end

  test "skipping every line is refused" do
    post add_items_inbound_email_path(inbound_emails(:waiting_order), format: :json),
         params: { items: [ { action: "skip", name: "Example Tent" } ] }, as: :json

    assert_response :unprocessable_entity
    assert_equal "received", inbound_emails(:waiting_order).reload.status
  end

  test "over JSON, posted lines replace the proposal and may drop some" do
    post add_items_inbound_email_path(inbound_emails(:waiting_order), format: :json),
         params: { items: [ { name: "Example Merino Socks", manufacturer: "Example Knits", category: "Clothing", quantity: 1 } ] }, as: :json

    assert_response :created
    assert_equal [ "Example Merino Socks" ], Item.where(id: response.parsed_body["created_item_ids"]).pluck(:name)
  end

  test "ignoring removes it from the waiting list" do
    post ignore_inbound_email_path(inbound_emails(:waiting_order))

    assert_equal "ignored", inbound_emails(:waiting_order).reload.status
    assert_not_includes InboundEmail.awaiting_review, inbound_emails(:waiting_order)
  end

  test "reading again without an LLM configured says so" do
    post retriage_inbound_email_path(inbound_emails(:unreadable))

    assert_redirected_to inbound_email_path(inbound_emails(:unreadable))
    follow_redirect!
    assert_select "p", /couldn't read it/
  end

  test "the index JSON filters by status" do
    get inbound_emails_path(format: :json, status: "added")

    assert_equal [ "handled@example.test" ], response.parsed_body.map { |email| email["message_id"] }
  end

  test "an item added from an email links back to it" do
    email = inbound_emails(:waiting_order)
    item = email.review!([ email.proposal.last.merge("action" => "add") ]).sole

    get item_path(item)
    assert_select "a[href='#{inbound_email_path(email)}']", "order email"
  end

  test "retailers can be added, paused and removed" do
    post retailers_path(format: :json), params: { retailer: { value: " Shop.Example ", name: "Shop" } }, as: :json
    assert_response :created
    retailer = Retailer.find(response.parsed_body["id"])
    assert_equal "shop.example", retailer.value

    patch retailer_path(retailer, format: :json), params: { retailer: { active: false } }, as: :json
    assert_not_includes Retailer.match_values, "shop.example"

    delete retailer_path(retailer, format: :json)
    assert_response :no_content
  end

  test "a duplicate retailer is refused" do
    post retailers_path(format: :json), params: { retailer: { value: "EXAMPLE-OUTFITTERS.TEST" } }, as: :json

    assert_response :unprocessable_entity
  end

  test "the inbox and retailer pages render" do
    [ inbound_emails_path, inbound_email_path(inbound_emails(:unreadable)), inbound_email_path(inbound_emails(:handled)), retailers_path ].each do |path|
      get path
      assert_response :success, path
    end
  end
end
