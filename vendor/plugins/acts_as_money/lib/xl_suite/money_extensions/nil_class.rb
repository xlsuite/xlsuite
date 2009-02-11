module XlSuite
  module MoneyExtensions
    module NilClass
      def to_money(currency=Money.default_currency)
        Money.zero(currency)
      end
    end
  end
end
