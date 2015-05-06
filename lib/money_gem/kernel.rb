module Kernel
  def Money(amount, currency = MoneyGem::Money.default_currency)
    MoneyGem::Money.new(amount, currency)
  end
end
