require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "GET new redirects to cart when cart is empty" do
    get new_order_path
    assert_redirected_to cart_path
  end

  test "GET new renders checkout form when cart has items" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
    get new_order_path
    assert_response :success
    assert_select "h1", text: "Checkout"
  end

  test "POST create places order and clears cart" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 2 }
    assert_difference "Order.count", 1 do
      assert_difference "OrderItem.count", 1 do
        post orders_path, params: {
          order: { customer_name: "Test User", customer_email: "test@example.com" }
        }
      end
    end
    order = Order.last
    assert_redirected_to order_path(order)
    assert_equal 4998, order.total_cents
  end

  test "POST create re-renders form with errors on invalid data" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
    post orders_path, params: { order: { customer_name: "", customer_email: "bad" } }
    assert_response :unprocessable_entity
  end

  test "GET show renders confirmation page" do
    get order_path(orders(:pending_order))
    assert_response :success
    assert_select "h1", text: /Order Confirmed/
  end
end
