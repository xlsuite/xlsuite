module ActsAsPeriod
  def acts_as_period(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    options.reverse_merge!(:allow_nil => false)

    attr_names = args.flatten.compact
    attr_names.each do |attr|
      code = <<-EOF
        # BEGIN -- acts_as_period #{attr}
        composed_of :#{attr}_accessor, :class_name => "Period", :mapping => [["#{attr}_length", "length"], ["#{attr}_unit", "unit"]], :allow_nil => #{options[:allow_nil]}
        
        validate :validate_#{attr}
        validates_numericality_of :#{attr}_length, :allow_nil => #{options[:allow_nil]}
        validates_inclusion_of :#{attr}_unit, :in => Period::ValidUnits, :allow_nil => #{options[:allow_nil]}
        protected :#{attr}_accessor, :#{attr}_accessor=

        def #{attr}
          self.#{attr}_accessor
        end

        def #{attr}=(value)
          @#{attr} = value
        end
        
        def validate_#{attr}
          case @#{attr}
          when NilClass
            self.#{attr}_accessor = nil if self.instance_variable_exists?("#{attr}")
          when String
            begin
              self.#{attr}_accessor = Period.parse(@#{attr})
            rescue
              self.errors.add("#{attr}", $!.message)
              return false
            end
          when Period
            self.#{attr}_accessor = @#{attr}
          else
            self.errors.add("#{attr}", "Expected to receive a nil, String or Period instance.  Instead, I received a #{attr.class.name} (#{attr.inspect})")
          end
        end
        
        # END -- acts_as_period #{attr}
      EOF

      self.class_eval code
    end
  end
end
