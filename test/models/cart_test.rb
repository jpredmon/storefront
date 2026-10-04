require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @session = {}
    @cart = Cart.new(@session)
  end

  test "starts empty" do
    assert @cart.empty?
    assert_equal 0, @cart.count
  end

  test "add_item increases count" do
    @cart.add_item(products(:tshirt).id, 2)
    assert_equal 2, @cart.count
    assert_not @cart.empty?
  end

  test "add_item to same product accumulates quantity" do
    @cart.add_item(products(:tshirt).id, 1)
    @cart.add_item(products(:tshirt).id, 1)
    assert_equal 2, @cart.count
  end

  test "remove_item empties single-item cart" do
    @cart.add_item(products(:tshirt).id, 1)
    @cart.remove_item(products(:tshirt).id)
    assert @cart.empty?
  end

  test "update_item sets quantity" do
    @cart.add_item(products(:tshirt).id, 1)
    @cart.update_item(products(:tshirt).id, 5)
    assert_equal 5, @cart.count
  end

  test "update_item to 0 removes item" do
    @cart.add_item(products(:tshirt).id, 1)
    @cart.update_item(products(:tshirt).id, 0)
    assert @cart.empty?
  end

  test "total_cents sums price times quantity" do
    @cart.add_item(products(:tshirt).id, 2)   # 2499 * 2 = 4998
    @cart.add_item(products(:poster).id, 1)   # 1499 * 1 = 1499
    assert_equal 6497, @cart.total_cents
  end

  test "clear empties the cart" do
    @cart.add_item(products(:tshirt).id, 3)
    @cart.clear
    assert @cart.empty?
  end

  test "items skips products that no longer exist" do
    @session[:cart] = { "99999" => 1 }
    cart = Cart.new(@session)
    assert_empty cart.items
  end

  test "count and empty? ignore products that no longer exist" do
    @session[:cart] = { "99999" => 3 }
    cart = Cart.new(@session)
    assert_equal 0, cart.count
    assert cart.empty?
  end

  test "add_item ignores zero and negative quantities" do
    assert_not @cart.add_item(products(:tshirt).id, 0)
    assert_not @cart.add_item(products(:tshirt).id, -3)
    assert @cart.empty?
  end

  test "add_item caps quantity at MAX_QUANTITY" do
    @cart.add_item(products(:tshirt).id, 60)
    @cart.add_item(products(:tshirt).id, 60)
    assert_equal Cart::MAX_QUANTITY, @cart.count
  end

  test "update_item caps quantity at MAX_QUANTITY" do
    @cart.add_item(products(:tshirt).id, 1)
    @cart.update_item(products(:tshirt).id, 1_000_000)
    assert_equal Cart::MAX_QUANTITY, @cart.count
  end

  test "update_item does not add products that are not in the cart" do
    @cart.update_item(products(:tshirt).id, 5)
    assert @cart.empty?
  end
end
