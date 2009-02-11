class RemoveDuplicateAccountConfigurations < ActiveRecord::Migration
  def self.up
    Configuration.find(:all, :conditions => {:account_id => nil, :account_wide => true}, :group => "name").each do |config|
      config.delete if Configuration.count(:all, :conditions => {:account_id => nil, :account_wide => true, :name => config.name}) > 1
    end
  end

  def self.down
  end

  class Configuration < ActiveRecord::Base; end
  class FloatConfiguration < Configuration; end
  class IntegerConfiguration < Configuration; end
  class PartyConfiguration < Configuration; end
  class ProductCategoryConfiguration < Configuration; end
  class ProductConfiguration < Configuration; end
  class StringConfiguration < Configuration; end
end
