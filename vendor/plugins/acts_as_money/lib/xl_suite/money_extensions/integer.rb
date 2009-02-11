module XlSuite
  module MoneyExtensions
    module Integer
      def to_money(currency=Money.default_currency)
        Money.new(self, currency)
      end
    end
  end
end
