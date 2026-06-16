require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    item = OrderItem.new(
      order: orders(:pending_order),
      product: products(:tshirt),
      quantity: 2,
      unit_price: 2499
    )
    assert item.valid?
  end

  test "invalid with zero quantity" do
    item = OrderItem.new(order: orders(:pending_order), product: products(:tshirt), quantity: 0, unit_price: 2499)
    assert_not item.valid?
  end

  test "subtotal_cents returns quantity times unit_price" do
    item = OrderItem.new(quantity: 3, unit_price: 1000)
    assert_equal 3000, item.subtotal_cents
  end
end
