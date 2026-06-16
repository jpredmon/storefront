require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "GET index returns 200" do
    get products_path
    assert_response :success
  end

  test "GET index renders product names" do
    get products_path
    assert_select "h5.card-title", text: products(:tshirt).name
  end

  test "GET show returns 200" do
    get product_path(products(:tshirt))
    assert_response :success
  end

  test "GET show displays product name and price" do
    product = products(:tshirt)
    get product_path(product)
    assert_select "h1", text: product.name
    assert_match "$24.99", response.body
  end

  test "GET show 404 for missing product" do
    get product_path(id: 99999)
    assert_response :not_found
  end
end
