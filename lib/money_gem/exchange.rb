require 'json'
require 'bigdecimal'

CURRENCIES = JSON.parse(IO.read('./lib/money_gem/currencies.json'))
EXCHANGE_RATES = JSON.parse(IO.read('./lib/money_gem/exchange_rates.json'))

class InvalidCurrency < StandardError
end

module MoneyGem
  class Exchange
    def convert(money, currency)
      amount_to_convert = money.amount
      input_currency = money.currency
      output_currency = currency
      wrong_currency = missing_currency(input_currency, output_currency)

      raise InvalidCurrency, "Invalid currency: #{wrong_currency}" unless currencies_present?(input_currency, output_currency)

      if input_currency == output_currency
        amount_to_convert
      else
        amount_to_convert * BigDecimal(EXCHANGE_RATES["#{input_currency}_#{output_currency}"].to_s)
      end
    end

    private

    def currencies_present?(input_currency, output_currency)
      CURRENCIES.include?(input_currency) && CURRENCIES.include?(output_currency)
    end

    def missing_currency(input_currency, output_currency)
      CURRENCIES.include?(input_currency) ? output_currency : input_currency
    end
  end
end
