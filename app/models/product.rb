class Product < ApplicationRecord
  validates :name, presence: true
  validates :price_cents, presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  def price
    price_cents.to_f / 100
  end

  def price=(dollars)
    self.price_cents = (dollars.to_f * 100).to_i
  end
end
