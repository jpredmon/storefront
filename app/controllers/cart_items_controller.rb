class CartItemsController < ApplicationController
  def create
    cart.add_item(params[:product_id], params[:quantity] || 1)
    redirect_to cart_path, notice: "Item added to cart."
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
