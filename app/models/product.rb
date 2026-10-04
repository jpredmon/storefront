class Product < ApplicationRecord
  # Keeps order history intact: a product that has been ordered can't be deleted.
  has_many :order_items, dependent: :restrict_with_error

  validates :name, presence: true
  # Upper bound keeps price_cents inside the 32-bit integer column.
  validates :price_cents, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than: 100_000_000 }

  def price
    BigDecimal(price_cents) / 100 if price_cents
  end

  # Parses through BigDecimal, not Float, so "19.99" becomes exactly 1999 cents.
  # Unparseable input becomes nil and is reported by the presence validation.
  def price=(dollars)
    amount = BigDecimal(dollars.to_s, exception: false)
    self.price_cents = amount&.finite? ? (amount * 100).round : nil
  end
end
