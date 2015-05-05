require 'spec_helper'

describe MoneyGem::Exchange do
  let(:exchange) { MoneyGem::Exchange.new }
  let(:money) { double('Money', amount: 10, currency: 'EUR') }

  describe '#convert' do
    before { stub_const('MoneyGem::Exchange::EXCHANGE_RATES', {'EUR_USD' => 1.3}) }

    context 'with correct currency input' do
      it 'returns a correct value' do
        expect(exchange.convert(money, 'USD')).to eq(13)
      end
    end

    context 'with incorrect currency input' do
      context 'when output currency is incorrect' do
        it 'raises InvalidCurrency' do
          expect { exchange.convert(money, 'NOK') }.to raise_exception(InvalidCurrency)
        end
      end

      context 'when input currency is incorrect' do
        let(:money) { double('Money', amount: 10, currency: 'NOK') }

        it 'raises InvalidCurrency' do
          expect { exchange.convert(money, 'USD') }.to raise_exception(InvalidCurrency)
        end
      end
    end
  end
end
