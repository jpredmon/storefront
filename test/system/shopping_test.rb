require "application_system_test_case"

class ShoppingTest < ApplicationSystemTestCase
  test "shopper buys a product from browsing to confirmation" do
    visit root_path
    within(".card", text: "Classic T-Shirt") { click_on "View" }
    fill_in "quantity", with: 2
    click_on "Add to Cart"

    assert_text "Item added to cart."
    assert_link "Cart (2)"
    assert_text "$49.98"

    click_on "Checkout →"
    fill_in "Full Name", with: "Pat Shopper"
    fill_in "Email", with: "pat@example.com"
    click_on "Place Order →"

    assert_text "Order Confirmed!"
    assert_text "Thanks, Pat Shopper."
    assert_text "Classic T-Shirt × 2"
    assert_link "Cart (0)"
  end

  test "shopper updates a quantity and removes an item" do
    visit product_path(products(:poster))
    click_on "Add to Cart"

    fill_in "quantity", with: 3
    click_on "Update"
    assert_text "Quantity updated."
    assert_link "Cart (3)"
    assert_text "$44.97"

    click_on "Remove"
    assert_text "Your cart is empty."
    assert_link "Cart (0)"
  end

  test "checkout shows validation errors" do
    visit product_path(products(:poster))
    click_on "Add to Cart"
    click_on "Checkout →"
    click_on "Place Order →"

    assert_text "Customer name can't be blank"
    assert_text "Customer email can't be blank"
  end

  test "flash message can be dismissed" do
    visit product_path(products(:poster))
    click_on "Add to Cart"

    within(".alert") { find(".btn-close").click }
    assert_no_text "Item added to cart."
  end
end
