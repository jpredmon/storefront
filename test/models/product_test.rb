require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid with all attributes" do
    product = Product.new(name: "Widget", price_cents: 999)
    assert product.valid?
  end

  test "invalid without name" do
    product = Product.new(price_cents: 999)
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "invalid without price_cents" do
    product = Product.new(name: "Widget")
    assert_not product.valid?
  end

  test "invalid with price_cents of zero" do
    product = Product.new(name: "Widget", price_cents: 0)
    assert_not product.valid?
  end

  test "invalid with negative price_cents" do
    product = Product.new(name: "Widget", price_cents: -1)
    assert_not product.valid?
  end

  test "price virtual attribute converts dollars to cents" do
    product = Product.new(name: "Widget")
    product.price = 9.99
    assert_equal 999, product.price_cents
  end

  test "price reader returns dollars" do
    product = Product.new(name: "Widget", price_cents: 2499)
    assert_in_delta 24.99, product.price, 0.001
  end

  # 19.99 * 100 is 1998.9999999999998 as a Float, so Float math loses a cent.
  test "price setter converts dollars to exact cents" do
    { "19.99" => 1999, "0.29" => 29, "1.15" => 115, 19.99 => 1999 }.each do |dollars, cents|
      product = Product.new(name: "Widget")
      product.price = dollars
      assert_equal cents, product.price_cents, "price = #{dollars.inspect}"
    end
  end

  test "price setter rounds to the nearest cent" do
    product = Product.new(name: "Widget")
    product.price = "19.999"
    assert_equal 2000, product.price_cents
  end

  test "blank, non-numeric, or non-finite price makes product invalid instead of raising" do
    [ "", "abc", nil, "Infinity", "NaN" ].each do |dollars|
      product = Product.new(name: "Widget")
      product.price = dollars
      assert_not product.valid?, "price = #{dollars.inspect}"
      assert_nil product.price_cents
    end
  end

  test "invalid with price of one million dollars or more" do
    product = Product.new(name: "Widget", price_cents: 100_000_000)
    assert_not product.valid?
  end

  test "price reader returns nil when no price is set" do
    assert_nil Product.new.price
  end

  test "cannot be destroyed once it has been ordered" do
    product = products(:tshirt)
    orders(:pending_order).order_items.create!(product: product, quantity: 1, unit_price: product.price_cents)

    assert_not product.destroy
    assert product.errors[:base].any?
    assert Product.exists?(product.id)
  end
end
