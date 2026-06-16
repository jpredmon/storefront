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
end
