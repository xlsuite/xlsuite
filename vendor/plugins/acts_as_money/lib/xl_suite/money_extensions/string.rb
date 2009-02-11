module XlSuite
  module MoneyExtensions
    module String
      def self.included(base)
        base.send :alias_method_chain, :to_money, :upcase
      end

      def to_money_with_upcase
        upcase.to_money_without_upcase
      end
    end
  end
end
