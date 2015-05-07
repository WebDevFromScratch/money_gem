require 'json'
require 'bigdecimal'
require 'open-uri'

CURRENCIES = JSON.parse(IO.read('./lib/money_gem/currencies.json'))

module MoneyGem
  class Exchange
    class InvalidCurrency < StandardError
    end

    def convert(money, currency)
      amount_to_convert = money.amount
      input_currency = money.currency
      output_currency = currency
      wrong_currency = missing_currency(input_currency, output_currency)

      raise InvalidCurrency, "Invalid currency: #{wrong_currency}" unless currencies_present?(input_currency, output_currency)

      if input_currency == output_currency
        amount_to_convert
      else
        amount_to_convert * BigDecimal(get_exchange_rate(input_currency, output_currency))
      end
    end

    private

    def currencies_present?(input_currency, output_currency)
      CURRENCIES.include?(input_currency) && CURRENCIES.include?(output_currency)
    end

    def missing_currency(input_currency, output_currency)
      CURRENCIES.include?(input_currency) ? output_currency : input_currency
    end

    def get_exchange_rate(input_currency, output_currency)
      JSON.parse(open("http://www.freecurrencyconverterapi.com/api/v3/convert?q=#{input_currency}_#{output_currency}&compact=ultra").read)["#{input_currency}_#{output_currency}"].to_s
    end
  end
end
