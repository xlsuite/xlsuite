module XlSuite
  module ActsAsMoney
    # Generates a #composed_of call, plus getter and setter methods to receive String
    # objects and transform them to Money objects using #to_money.
    #
    # == Options
    # * :allow_nil => defaults to true.
    #
    # == Examples
    #  class OrderLine
    #    acts_as_money :unit_price, :allow_nil => false
    #  end
    #
    #  class Product
    #    acts_as_money :retail_price
    #  end
    def acts_as_money(*args)
      options = args.last.kind_of?(Hash) ? args.pop : Hash.new
      options.reverse_merge!(:allow_nil => true)

      args.each do |method_name|
        self.class_eval <<-"end_eval"
          composed_of :#{method_name}_amount, :class_name => "Money", :mapping => [["#{method_name}_cents", "cents"], ["#{method_name}_currency", "currency"]], :allow_nil => #{options[:allow_nil]}

          def #{method_name}
            self.#{method_name}_cents = 0 unless self.#{method_name}_cents
            self.#{method_name}_amount
          end

          def #{method_name}=(value)
            case value
            when NilClass
              self.#{method_name}_amount = nil
            when Money
              self.#{method_name}_amount = value
            when String
              self.#{method_name}_amount = value.blank? ? Money.zero : value.to_money
            else
              raise ArgumentError, "##{method_name}= expects nil, a Money instance, or a String of the form '15.00 CAD'"
            end
          end
        end_eval
      end
    end
  end
end
