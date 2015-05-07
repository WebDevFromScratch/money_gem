require 'spec_helper'

describe MoneyGem::Money do
  describe 'Kernel#Money' do
    it 'creates a Money instance' do
      expect(Money(10, 'USD')).to be_an_instance_of(MoneyGem::Money)
    end
  end

  describe 'Class methods' do
    describe '.initialize' do
      context 'with valid arguments' do
        it 'should successfully create an instance of Money' do
          expect(MoneyGem::Money.new(10, 'USD')).to be_an_instance_of(MoneyGem::Money)
        end
      end
      context 'without currency' do
        it 'should raise an ArgumentError' do
          expect { MoneyGem::Money.new(10) }.to raise_exception(ArgumentError)
        end

        context 'used with .using_default_currency' do
          it 'should successfully create an instance of MoneyGem::Money' do
            expect(MoneyGem::Money.using_default_currency('USD') { MoneyGem::Money.new(10) }).to be_an_instance_of(MoneyGem::Money)
          end
        end
      end
    end

    describe '.from_usd' do
      let(:money_usd) { MoneyGem::Money.from_usd(10) }

      it 'should create an expected MoneyGem::Money instance' do
        expect(money_usd).to be_an_instance_of(MoneyGem::Money)
        expect(money_usd.currency).to eq('USD')
        expect(money_usd.amount).to eq(10)
      end
    end

    describe '.from_eur' do
      let(:money_eur) { MoneyGem::Money.from_eur(10) }

      it 'should create an expected MoneyGem::Money instance' do
        expect(money_eur).to be_an_instance_of(MoneyGem::Money)
        expect(money_eur.currency).to eq('EUR')
        expect(money_eur.amount).to eq(10)
      end
    end

    describe '.from_gbp' do
      let(:money_gbp) { MoneyGem::Money.from_gbp(10) }

      it 'should create an expected MoneyGem::Money instance' do
        expect(money_gbp).to be_an_instance_of(MoneyGem::Money)
        expect(money_gbp.currency).to eq('GBP')
        expect(money_gbp.amount).to eq(10)
      end
    end

    describe '.exchange' do
      it 'should return a MoneyGem::Exchange instance' do
        expect(MoneyGem::Money.exchange).to be_an_instance_of(MoneyGem::Exchange)
      end
    end
  end

  describe 'Instance methods' do
    let(:money) { MoneyGem::Money.new(10, 'USD') }

    describe '#<=>' do
      let(:money_1) { MoneyGem::Money.new(10, 'USD') }
      let(:money_2) { MoneyGem::Money.new(10, 'EUR') }
      let(:money_3) { MoneyGem::Money.new(13, 'USD') }
      before { allow_any_instance_of(MoneyGem::Exchange).to receive(:get_exchange_rate).and_return('1.3') }

      it 'should correctly compare Money instances' do
        expect(money_1 < money_2).to eq(true)
        expect(money_3 == money_2).to eq(true)
      end
    end

    describe '#to_s' do
      it 'should return a properly formatted string' do
        expect(money.to_s).to eq('10.00 USD')
      end
    end

    describe '#inspect' do
      it 'should return a properly formatted string' do
        expect(money.inspect).to eq('#<Money 10.00 USD>')
      end
    end

    describe '#exchange_to' do
      let(:exchange) { double('Exchange', convert: true) }
      before { allow(money.class).to receive(:exchange).and_return(exchange) }

      it 'should call the Exchange#convert method' do
        expect(money.class.exchange).to receive(:convert)

        money.exchange_to('EUR')
      end

      it 'should update currency' do
        money.exchange_to('EUR')

        expect(money.currency).to eq('EUR')
      end
    end

    describe '#method_missing' do
      before { stub_const('CURRENCIES', ['USD', 'EUR']) }

      context 'with correct conversion method' do
        it 'should call the #exchange_to method with expected argument' do
          expect(money).to receive(:exchange_to)
          expect { money.to_eur }.not_to raise_exception
        end
      end

      context 'with undefined method' do
        it 'should raise NoMethodError' do
          expect { money.to_wtf }.to raise_exception(NoMethodError)
        end
      end
    end

    describe '#calculate_in' do
      let(:exchange) { double('Exchange', convert: 8) }
      before { allow(money.class).to receive(:exchange).and_return(exchange) }

      it 'should call the Exchange#convert method' do
        expect(money.class.exchange).to receive(:convert)

        money.calculate_in('EUR')
      end

      it 'should return an expected MoneyGem::Money instance' do
        new_money = money.calculate_in('EUR')

        expect(new_money).to be_an_instance_of(MoneyGem::Money)
        expect(new_money.currency).to eq('EUR')
        expect(new_money.amount).to eq(8)
      end
    end

    describe '#arithmetic methods' do
      let(:money_usd) { MoneyGem::Money.new(10, 'USD') }
      let(:money_eur) { MoneyGem::Money.new(10, 'EUR') }
      before { allow(money_eur).to receive(:calculate_in).and_return(MoneyGem::Money.new(20, 'USD')) }

      context 'when currencies are different' do
        it 'should execute #calculate_in' do
          expect(money_eur).to receive(:calculate_in).and_return(MoneyGem::Money.new(20, 'USD'))

          money_usd + money_eur
        end
      end

      describe '#+' do
        it 'should return a correct MoneyGem::Money instance' do
          expect(money_usd + money_eur).to eq(MoneyGem::Money.new(30, 'USD'))
        end
      end

      describe '#-' do
        it 'should return a correct MoneyGem::Money instance' do
          expect(money_usd - money_eur).to eq(MoneyGem::Money.new(-10, 'USD'))
        end
      end

      describe '#*' do
        it 'should return a correct MoneyGem::Money instance' do
          expect(money_usd * 2).to eq(MoneyGem::Money.new(20, 'USD'))
        end
      end

      describe '#/' do
        it 'should return a correct MoneyGem::Money instance' do
          expect(money_usd / 2).to eq(MoneyGem::Money.new(5, 'USD'))
        end
      end
    end
  end
end
