require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionTest < Test::Unit::TestCase
  context "Calling #update_next_renewal_at" do
    setup do
      @next_renewal_at = Time.now.utc
      @subscription =  Subscription.new(:next_renewal_at => @next_renewal_at, :renewal_period => "1 month",
        :account_id => 1, :authorization_code => "test", :subject => Party.first, :payer => Party.first, :payment_method => "credit_card")
      @subscription.save!
      @subscription.update_next_renewal_at
    end
    
    should "update the next_renewal_at_correctly" do
      @subscription.reload
      assert_equal (@next_renewal_at + 1.month.to_i).to_i, @subscription.next_renewal_at.to_i
    end  
  end
end
