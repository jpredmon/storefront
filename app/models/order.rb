class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :customer_name,  presence: true
  validates :customer_email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not valid" }
  validates :total_cents, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :status, presence: true
end
