require File.dirname(__FILE__) + '/../test_helper'

class PaymentTest < Test::Unit::TestCase
  def setup
    @account = Account.find(1)
    @invoice = invoices(:johns_invoice)
    @bob = parties(:bob)
  end

  context "A started Check payment" do
    setup do
      @payment = @account.payments.build(:payment_method => "check", :description => "Payment for invoice #20080129", :amount => "132.22 cad")
      @payment.save!
      @payable = @payment.payables.build(:amount => "132.22 cad", :subject => @invoice, :account => @account)
      @payable.start!(@bob)
      @payment.reload
    end

    should "be in the 'pending' state" do
      assert_match /pending/i, @payment.state
    end
    
    should "record who started the payment" do
      assert_equal @bob.name.to_s, @payment.transitions.find(:first, :order => "id DESC").creator.name.to_s
    end
    context "being received" do
      setup do
        @payable.receive!(@bob)
        @payment.reload
      end
      
      should "be in the 'authorized' state" do
        assert_match /authorized/i, @payment.state
      end

      should "remember who received the payment" do
        assert_equal @bob.name.to_s, @payment.transitions.find(:first, :order => "id DESC").creator.name.to_s
      end
    end

    context "being completed" do
      setup do
        @payable.complete!(@bob)
        @payment.reload
      end

      should "be in the 'paid' state" do
        assert_match /paid/i, @payment.state
      end

      should "remember who completed the payment" do
        assert_equal @bob.name.to_s, @payment.transitions.find(:first, :order => "id DESC").creator.name.to_s
      end
    end

    context "being cancelled" do
      setup do
        @payable.cancel!(@bob)
        @payment.reload
      end

      should "be in the 'cancelled' state" do
        assert_match /cancelled/i, @payment.state
      end

      should "remember who cancelled the payment" do
        assert_equal @bob.name.to_s, @payment.transitions.find(:first, :order => "id DESC").creator.name.to_s
      end
    end      
  end
end
