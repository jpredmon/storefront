require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    order = Order.new(
      customer_name: "John",
      customer_email: "john@example.com",
      total_cents: 999,
      status: "pending"
    )
    assert order.valid?
  end

  test "invalid without customer_name" do
    order = Order.new(customer_email: "a@b.com", total_cents: 999, status: "pending")
    assert_not order.valid?
  end

  test "invalid without customer_email" do
    order = Order.new(customer_name: "John", total_cents: 999, status: "pending")
    assert_not order.valid?
  end

  test "invalid with malformed email" do
    order = Order.new(customer_name: "John", customer_email: "notanemail", total_cents: 999, status: "pending")
    assert_not order.valid?
  end

  test "invalid with total_cents of zero" do
    order = Order.new(customer_name: "John", customer_email: "j@example.com", total_cents: 0, status: "pending")
    assert_not order.valid?
  end

  test "has_many order_items" do
    order = orders(:pending_order)
    order.order_items.create!(product: products(:tshirt), quantity: 2, unit_price: 1999)
    assert_equal 1, order.order_items.count
  end
end
