require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admin_users(:one)
  end

  test "GET index redirects to login when not authenticated" do
    get admin_products_path
    assert_redirected_to new_admin_admin_user_session_path
  end

  test "GET index returns 200 when authenticated" do
    sign_in @admin
    get admin_products_path
    assert_response :success
  end

  test "POST create creates product and redirects" do
    sign_in @admin
    assert_difference "Product.count", 1 do
      post admin_products_path, params: {
        product: { name: "New Item", price: "12.99", description: "Great item" }
      }
    end
    assert_redirected_to admin_products_path
    assert_equal 1299, Product.last.price_cents
  end

  test "DELETE destroy removes product" do
    sign_in @admin
    product = products(:tshirt)
    assert_difference "Product.count", -1 do
      delete admin_product_path(product)
    end
    assert_redirected_to admin_products_path
  end

  test "PATCH update changes product attributes" do
    sign_in @admin
    patch admin_product_path(products(:tshirt)), params: {
      product: { name: "Updated Tee", price: "29.99" }
    }
    assert_redirected_to admin_products_path
    assert_equal "Updated Tee", products(:tshirt).reload.name
    assert_equal 2999, products(:tshirt).reload.price_cents
  end
end
