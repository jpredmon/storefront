class Cart
  MAX_QUANTITY = 99

  def initialize(session)
    @session = session
    @session[:cart] ||= {}
  end

  # Returns false (and adds nothing) for a quantity below 1.
  def add_item(product_id, quantity = 1)
    quantity = quantity.to_i
    return false if quantity < 1

    key = product_id.to_s
    @session[:cart][key] = [ @session[:cart].fetch(key, 0) + quantity, MAX_QUANTITY ].min
    true
  end

  def remove_item(product_id)
    @session[:cart].delete(product_id.to_s)
  end

  def update_item(product_id, quantity)
    key = product_id.to_s
    return unless @session[:cart].key?(key)

    quantity = quantity.to_i
    quantity <= 0 ? remove_item(product_id) : @session[:cart][key] = [ quantity, MAX_QUANTITY ].min
  end

  def items
    products = Product.where(id: @session[:cart].keys).index_by { |p| p.id.to_s }
    @session[:cart].filter_map do |product_id, quantity|
      product = products[product_id.to_s]
      { product: product, quantity: quantity } if product
    end
  end

  def total_cents
    items.sum { |item| item[:product].price_cents * item[:quantity] }
  end

  # count and empty? go through items so products deleted since being added don't count.
  def count
    items.sum { |item| item[:quantity] }
  end

  def empty?
    items.empty?
  end

  def clear
    @session[:cart] = {}
  end
end
