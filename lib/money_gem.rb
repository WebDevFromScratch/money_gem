require 'money_gem/version'
require 'money_gem/exchange'
require 'money_gem/kernel'
require 'bigdecimal'

module MoneyGem
  class Money
    include Comparable

    class << self
      attr_accessor :default_currency
    end

    attr_accessor :amount, :currency

    def initialize(amount, currency = self.class.default_currency)
      raise ArgumentError, 'No currency given' if currency == nil
      @amount = BigDecimal(amount.to_s)
      @currency = currency.to_s
    end

    def <=>(anOther)
      exchange_to('USD').amount <=> anOther.exchange_to('USD').amount
    end

    [:from_usd, :from_eur, :from_gbp].each do |method_name|
      define_singleton_method method_name do |amount|
        new(amount, method_name.to_s.split('_').last.upcase)
      end
    end

    [:+, :-].each do |method_name|
      define_method method_name do |other|
        recalculated_other = calculate_if_necessary(other)

        self.class.new(amount.send(method_name, recalculated_other.amount), currency)
      end
    end

    [:*, :/].each do |method_name|
      define_method method_name do |number|
        self.class.new(amount.send(method_name, number), currency)
      end
    end

    def method_missing(name)
      name = name.to_s
      if correct_conversion_method?(name)
        exchange_to(name.split('_').last.upcase)
      else
        raise NoMethodError, "Unknown method: #{name}"
      end
    end

    def respond_to?(name)
      (correct_conversion_method?(name.to_s) || arithmetic_method?(name.to_s)) ? true : super
    end

    def calculate_in(currency)
      new_amount = self.class.exchange.convert(self, currency)
      self.class.new(new_amount, currency)
    end

    def exchange_to(currency)
      self.amount = self.class.exchange.convert(self, currency)
      self.currency = currency
      self
    end

    def to_s
      "#{amount_with_two_decimals} #{currency}"
    end

    def inspect
      "#<Money #{self.to_s}>"
    end

    def self.exchange
      MoneyGem::Exchange.new
    end

    def self.using_default_currency(currency)
      begin
        self.default_currency = currency

        yield
      ensure
        self.default_currency = nil
      end
    end

    private

    def amount_with_two_decimals
      sprintf('%.2f', amount)
    end

    def correct_conversion_method?(name)
      name.split('_').count == 2 && name.split('_').first == 'to' && CURRENCIES.include?(name.split('_').last.upcase)
    end

    def arithmetic_method?(name)
      ['+', '-', '*', '/'].include?(name)
    end

    def calculate_if_necessary(other)
      (currency == other.currency) ? other : other.calculate_in(currency)
    end
  end
end
