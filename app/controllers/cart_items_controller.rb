class CartItemsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    if cart.add_item(product.id, params[:quantity] || 1)
      redirect_to cart_path, notice: "Item added to cart."
    else
      redirect_to product, alert: "Quantity must be at least 1."
    end
  end

  def update
    cart.update_item(params[:id], params[:quantity])
    redirect_to cart_path, notice: "Quantity updated."
  end

  def destroy
    cart.remove_item(params[:id])
    redirect_to cart_path, notice: "Item removed."
  end
end
