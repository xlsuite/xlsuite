module ActsAsHashable
  def acts_as_hashable(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    
    attr_names = args.flatten.compact
    attr_names.each do |attr|
      self.class_eval <<-end_eval
        has_many :#{attr}, #{options.inspect}
        before_validation :set_account_of_#{attr}
        
        def #{attr}_with_hash=(object)
          object = object.map(&:last).map {|attrs| #{attr.to_s.classify}.new(attrs)} if object.kind_of?(Hash)
          self.#{attr}_without_hash = object
        end

        alias_method_chain :#{attr}=, :hash
        
        def set_account_of_#{attr}
          if self.respond_to?(:account) && self.account 
            self.#{attr}.each do |o|
              o.account = self.account
            end
          end
        end
      end_eval
    end
  end
end
