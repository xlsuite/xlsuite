module XlSuite
  module MoneyExtensions
    module Float
      def to_money(currency=Money.default_currency)
        Money.new((self * 100.0).ceil, currency)
      end
    end
  end
end
