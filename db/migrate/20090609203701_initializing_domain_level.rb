class InitializingDomainLevel < ActiveRecord::Migration
  def self.up
    Domain.all.each do |domain|
      domain.update_attribute(:level, (domain.name.split(".").size-1))
    end
  end

  def self.down
  end
end
