require File.dirname(__FILE__) + '/../test_helper'

class ActiveRecordWarningsTest < Test::Unit::TestCase
  setup do
    @account = Account.new
  end
  
  context "Calling #warnings on an ActiveRecord object" do
    should "return ActiveRecord::Warnings class" do
      assert_equal ActiveRecord::Warnings, @account.warnings.class
    end
  end
  
  context "Adding warnings" do
    context "on base" do
      setup do
        @account.warnings.add_to_base("This is a warning")
      end
      
      should "add the warning message correctly" do
        assert_equal "This is a warning", @account.warnings.on_base
      end
    end
    
    context "on an attribute" do
      setup do
        @account.warnings.add(:expires_at, "cannot be null")
      end
      
      should "add the warning message correctly" do
        assert_equal "cannot be null", @account.warnings[:expires_at]
      end
    end
  end
  
  context "Calling #clear on an ActiveRecord::Warnings that has warning messages inside" do
    setup do
      @account.warnings.add_to_base("This is a warning")
      assert_equal false, @account.warnings.instance_variable_get(:@warnings).empty?
      @account.warnings.clear
    end
    
    should "empty the @warnings instance" do
      assert_equal true, @account.warnings.instance_variable_get(:@warnings).empty?
    end
  end
end
