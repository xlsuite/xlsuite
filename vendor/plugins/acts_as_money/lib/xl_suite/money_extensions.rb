module XlSuite
  module MoneyExtensions
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      base.send :alias_method_chain, :format, :zero
    end

    module InstanceMethods
      def format_with_zero(*rules)
        return "" if zero? unless rules.include?(:no_blank)
        format_without_zero(*rules)
      end

      def zero?
        self.cents.zero?
      end

      def nonzero?
        !self.zero?
      end
      
      def blank?
        self.cents.blank?
      end

      def round_to_nearest_dollar
        self.class.new((cents / 100.0).ceil * 100, self.currency)
      end

      def to_f
        self.cents / 100.0
      end

      def floor
        self.class.new(self.cents.floor, self.currency)
      end

      def ceil
        self.class.new(self.cents.ceil, self.currency)
      end

      def round
        self.class.new(self.cents.round, self.currency)
      end

      def abs
        self.class.new(self.cents.abs, self.currency)
      end

      def to_liquid
        format(:with_currency, :html)
      end
    end

    module ClassMethods
      def penny(currency=Money.default_currency)
        Money.new(1, currency)
      end

      def zero(currency=Money.default_currency)
        Money.new(0, currency)
      end
    end
  end
end
