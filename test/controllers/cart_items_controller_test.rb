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

  test "PATCH update changes quantity" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }
    patch cart_item_path(products(:tshirt).id), params: { quantity: 3 }
    assert_redirected_to cart_path
  end
end
