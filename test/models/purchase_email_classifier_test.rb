require "test_helper"

class PurchaseEmailClassifierTest < ActiveSupport::TestCase
  def classify(from: "A Person <person@example.org>", subject:, body:, retailers: [])
    PurchaseEmailClassifier.new(from: from, subject: subject, body: body, retailers: retailers).result
  end

  test "an order confirmation passes on its language alone" do
    result = classify(subject: "Fwd: Your order is confirmed", body: "Order number 123. Subtotal $40. Qty 1.")

    assert result.purchase?
    assert_includes result.signals, "subject:your order"
  end

  test "a known retailer anywhere in a forwarded body counts" do
    result = classify(subject: "Fwd: hello", body: "From: Shop <orders@example-outfitters.test>\nThanks!",
                      retailers: [ "example-outfitters.test" ])

    assert result.purchase?
    assert_includes result.signals, "retailer:example-outfitters.test"
  end

  test "ordinary mail does not pass" do
    assert_not classify(subject: "Weekend plans", body: "Want to hike Saturday?").purchase?
  end

  test "a word inside another word is not a signal" do
    assert_not classify(subject: "Reordering the shelves", body: "Itemised later.").purchase?
  end
end
