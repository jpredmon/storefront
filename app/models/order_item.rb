class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity,   presence: true, numericality: { only_integer: true, greater_than: 0 }
  # unit_price is copied from the product at checkout, so later price changes don't
  # rewrite what past customers paid.
  validates :unit_price, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def subtotal_cents
    quantity * unit_price
  end
end
