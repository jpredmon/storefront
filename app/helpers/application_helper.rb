module ApplicationHelper
  def price_in_dollars(cents)
    "$#{'%.2f' % (cents / 100.0)}"
  end
end
