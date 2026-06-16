class Cart
  def initialize(session)
    @session = session
    @session[:cart] ||= {}
  end

  def add_item(product_id, quantity = 1)
    key = product_id.to_s
    @session[:cart][key] ||= 0
    @session[:cart][key] += quantity.to_i
  end

  def remove_item(product_id)
    @session[:cart].delete(product_id.to_s)
  end

  def update_item(product_id, quantity)
    quantity = quantity.to_i
    quantity <= 0 ? remove_item(product_id) : @session[:cart][product_id.to_s] = quantity
  end

  def items
    @session[:cart].filter_map do |product_id, quantity|
      product = Product.find_by(id: product_id)
      { product: product, quantity: quantity } if product
    end
  end

  def total_cents
    items.sum { |item| item[:product].price_cents * item[:quantity] }
  end

  def count
    @session[:cart].values.sum
  end

  def empty?
    @session[:cart].empty?
  end

  def clear
    @session[:cart] = {}
  end
end
