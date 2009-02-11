class AddIndustryAndMainThemeCategoriesToXlsuite < ActiveRecord::Migration
  def self.up
    xlsuite_domain = Domain.find_by_name("xlsuite.com")
    return unless xlsuite_domain
    xlsuite_acct = xlsuite_domain.account
    industry = Category.find(:first, :conditions => {:label => "industry", :account_id => xlsuite_acct.id})
    unless industry
      Category.create!(:label => "industry", :name => "Industry", :account_id => xlsuite_acct.id)
    end
    main_theme = Category.find(:first, :conditions => {:label => "main_theme", :account_id => xlsuite_acct.id})
    unless main_theme
      Category.create!(:label => "main_theme", :name => "Main theme", :account_id => xlsuite_acct.id)
    end
  end

  def self.down
    xlsuite_domain = Domain.find_by_name("xlsuite.com")
    return unless xlsuite_domain
    xlsuite_acct = xlsuite_domain.account
    %w(industry main_theme).each do |label|
      cat = Category.find(:first, :conditions => {:label => label, :account_id => xlsuite_acct.id})
      next unless cat
      cat.destroy
    end
  end
  
  class Category < ActiveRecord::Base; end
end
