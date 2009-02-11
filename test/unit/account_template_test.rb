require File.dirname(__FILE__) + '/../test_helper'

class AccountTemplateTest < ActiveSupport::TestCase
  context "An existing account template" do
    setup do
      @trunk_acct = Account.new
      @trunk_acct.expires_at = 1.year.from_now
      @trunk_acct.save!
      @at = AccountTemplate.create!(:name => "Test template", :description => "This is a description of my test template",
        :trunk_account => @trunk_acct)
    end
    
    context "with no stable version" do
      context "calling #rollback_stable!" do
        should "return false" do
          deny @at.rollback_stable!
        end
      end
    end
    
    context "with stable version" do
      setup do
        @stable_acct = Account.new
        @stable_acct.expires_at = 1.year.from_now
        @stable_acct.save!
        @at.stable_account = @stable_acct
      end
      
      context "and previous stable versions" do
        setup do
          @prev_stable_acct = Account.new
          @prev_stable_acct.expires_at = 1.year.from_now
          @prev_stable_acct.save!
          @at.previous_stables = [@prev_stable_acct.id]
          @at.save!
        end
        
        context "calling #rollback_stable!" do
          setup do
            @prev_stables_size = @at.previous_stables.size
            @result = @at.rollback_stable!
          end
          
          should "return true" do
            assert_equal true, @result
          end
          
          should "decrease the size of previous_stables" do
            assert_equal @prev_stables_size - 1, @at.previous_stables.size
          end
          
          should "assign the previous stable as the current stable" do
            assert_equal @prev_stable_acct.id, @at.stable_account.id
          end
        end
      end
      
      context "and NO previous stable version" do
        context "calling #rollback_stable!" do
          setup do
            @result = @at.rollback_stable!
          end
          
          should "return false" do
            assert_equal false, @result
          end
        end
      end
    end
  end
end
