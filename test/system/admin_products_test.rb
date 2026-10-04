require "application_system_test_case"

class AdminProductsTest < ApplicationSystemTestCase
  setup do
    AdminUser.create!(email: "system@storefront.test", password: "password123")
    visit new_admin_admin_user_session_path
    fill_in "Email", with: "system@storefront.test"
    fill_in "Password", with: "password123"
    click_on "Log in"
    assert_text "Signed in successfully."
  end

  test "flash message can be dismissed" do
    within(".alert") { find(".btn-close").click }
    assert_no_text "Signed in successfully."
  end

  test "admin creates a product with a price in dollars and cents" do
    click_on "New Product"
    fill_in "Name", with: "Canvas Cap"
    fill_in "Price ($)", with: "19.99"
    click_on "Create Product"

    assert_text "Product created."
    assert_selector "tr", text: "Canvas Cap $19.99"
  end

  test "admin edits a product" do
    within("tr", text: "Classic T-Shirt") { click_on "Edit" }
    assert_field "Price ($)", with: "24.99"
    fill_in "Name", with: "Classic Tee"
    click_on "Update Product"

    assert_text "Product updated."
    assert_selector "tr", text: "Classic Tee $24.99"
  end

  test "deleting a product asks for confirmation first" do
    row = find("tr", text: "Art Poster")

    dismiss_confirm("Delete Art Poster?") { row.click_on "Delete" }
    assert_selector "tr", text: "Art Poster"

    accept_confirm("Delete Art Poster?") { row.click_on "Delete" }
    assert_text "Product deleted."
    assert_no_selector "tr", text: "Art Poster"
  end

  test "a product that has been ordered cannot be deleted" do
    product = products(:tshirt)
    orders(:pending_order).order_items.create!(product: product, quantity: 1, unit_price: product.price_cents)
    visit admin_products_path

    accept_confirm { find("tr", text: "Classic T-Shirt").click_on "Delete" }
    assert_text "Cannot delete"
    assert_selector "tr", text: "Classic T-Shirt"
  end

  test "admin logs out" do
    click_on "Log Out"
    assert_text "Signed out successfully."

    visit admin_products_path
    assert_current_path new_admin_admin_user_session_path
  end
end
