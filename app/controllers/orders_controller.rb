class OrdersController < ApplicationController
  def new
    redirect_to(cart_path, alert: "Your cart is empty.") and return if cart.empty?
    @order = Order.new
    @cart  = cart
  end

  def create
    @cart = cart
    if @cart.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    @order = Order.new(order_params)
    @order.total_cents = @cart.total_cents
    @order.status      = "pending"

    ActiveRecord::Base.transaction do
      if @order.save
        @cart.items.each do |item|
          @order.order_items.create!(
            product:    item[:product],
            quantity:   item[:quantity],
            unit_price: item[:product].price_cents
          )
        end
        cart.clear
        # Remember which orders this browser placed; only those are viewable in #show.
        session[:order_ids] = Array(session[:order_ids]) << @order.id
        redirect_to @order, notice: "Order placed! Thanks for your purchase."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def show
    # Scoping to this session's orders makes any other id a 404, so customer details
    # can't be read by guessing ids.
    @order = Order.includes(order_items: :product).where(id: session[:order_ids]).find(params[:id])
  end

  private

  def order_params
    params.require(:order).permit(:customer_name, :customer_email)
  end
end
