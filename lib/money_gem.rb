require 'money_gem/version'
require 'money_gem/exchange'
require 'bigdecimal'

module Kernel
  def Money(amount, currency = MoneyGem::Money.default_currency)
    MoneyGem::Money.new(amount, currency)
  end
end

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
        self.new(amount, method_name.to_s.split('_').last.upcase)
      end
    end

    [:+, :-, :*, :/].each do |method_name|
      define_method method_name do |other|
        recalculated_other = calculate_if_necessary(other)

        self.class.new(amount.send(method_name, recalculated_other.amount), currency)
      end
    end

    def method_missing(name)
      name = name.to_s
      if correct_conversion_method?(name)
        self.exchange_to(name.split('_').last.upcase)
      else
        raise NoMethodError, "Unknown method: #{name}"
      end
    end

    def respond_to?(name)
      if correct_conversion_method?(name.to_s) || ['+', '-', '*', '/'].include?(name.to_s)
        true
      else
        super
      end
    end

    def calculate_in(currency)
      new_amount = self.class.exchange.convert(self, currency)
      new_money = self.class.new(new_amount, currency)
      new_money
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
      Exchange.new
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

    def calculate_if_necessary(other)
      if currency == other.currency
        other
      else
        other.calculate_in(currency)
      end
    end
  end
end
