require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  test "POST create adds item and redirects to cart" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 2 }
    assert_redirected_to cart_path
    follow_redirect!
    assert_match "Item added to cart", response.body
  end

  test "DELETE destroy removes item and redirects" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
    delete cart_item_path(products(:tshirt).id)
    assert_redirected_to cart_path
  end

  test "POST create with a nonexistent product returns 404" do
    post cart_items_path, params: { product_id: 99999, quantity: 1 }
    assert_response :not_found
  end

  test "POST create with a non-positive quantity does not add the item" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 0 }
    assert_redirected_to product_path(products(:tshirt))
    follow_redirect!
    assert_match "Quantity must be at least 1", response.body
    assert_match "Cart (0)", response.body
  end

  test "PATCH update changes quantity" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
    patch cart_item_path(products(:tshirt).id), params: { quantity: 3 }
    assert_redirected_to cart_path
  end
end
