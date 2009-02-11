require File.dirname(__FILE__) + '/../test_helper'

class InvoiceTest < Test::Unit::TestCase
  def setup
    @account = accounts(:wpul)
    @bob = parties(:bob)
  end
  
  context "Voiding an invoice" do
    setup do
      @order = @account.orders.create!(:invoice_to => parties(:bob), :date => Time.now)
      @order.lines.create!(:product => products(:fish), :quantity => 5.0)
      @order.lines.create!(:description => "Fish shipping fee is free", :comment => "You do not need to pay for fish shipping fee")
      @order.lines.create!(:product => products(:dog), :quantity => 1.0)
      @order.reload

      @invoice = @order.generate_new_invoice!    
      
      @invoice.void!(@bob)
    end
    
    should "change the quantity invoiced of the related order lines" do
      @order.reload
      @order.lines.each do |ol|
        assert_equal BigDecimal.new("0.0"), ol.quantity_invoiced
      end
    end
  end
  
  context "An existing invoice" do
    setup do
      @invoice = invoices(:johns_invoice)
    end

    should "belong to an account" do
      owner = Account.find(:first)
      assert_nothing_raised {
        @invoice = Invoice.create!(:customer => parties(:mary), :date => Date.today)
      }
      assert_equal @invoice.account, owner
      assert_equal @invoice, owner.invoices.find(@invoice.id)
    end
  end

  context "A newly created invoice" do
    setup do
      @invoice = Invoice.create!(:customer => parties(:mary), :date => Date.today)
      @invoice.reload
    end

    should "have an invoice number assigned" do
      assert_not_nil @invoice.number
    end

    should "have a non-zero invoice number" do
      assert_not_equal '0', @invoice.number.to_s
    end
  end

  context "An existing invoice with payments being voided" do
    setup do
      @invoice = invoices(:peters_invoice) # Peter's invoice has a payment
      @invoice.void!(@bob)
    end

    should "be flagged void" do
      assert @invoice.void?
    end

    should "void all payables" do
      assert @invoice.payables.all?(&:void?)
    end

    should "have a total of zero" do
      assert_equal Money.zero("CAD"), @invoice.total_amount("CAD")
    end

    should "have no balance left to pay" do
      assert_equal Money.zero("CAD"), @invoice.balance("CAD")
    end
  end

  context "An existing invoice created from an order" do
    setup do
      @order = Order.new(:account => @account, :date => Date.today, :customer => @bob)
      @order.save(false)

      @invoice = Invoice.new(:account => @account, :order => @order, :date => Date.today, :customer => @bob)
      @invoice.save(false)
    end

    context "with a completed payments on the order and the invoice" do
      setup do
        @payment = Payment.create!(:account => @account, :payment_method => "check", :amount => 8.to_money)
        @payment.payables << Payable.new(:subject => @order, :amount => 15.to_money)
        @payment.complete!(@bob)

        @payment = Payment.create!(:account => @account, :payment_method => "check", :amount => 7.to_money)
        @payment.payables << Payable.new(:subject => @invoice, :amount => 15.to_money)
        @payment.complete!(@bob)
      end

      should "include both the order and invoice amounts in it's calculations" do
        assert_equal 15.to_money, @invoice.reload.completed_payments_amount
      end
    end

    context "with a completed payment on the invoice" do
      setup do
        @payment = Payment.create!(:account => @account, :payment_method => "check", :amount => 15.to_money)
        @payment.payables << Payable.new(:subject => @order, :amount => 15.to_money)
        @payment.complete!(@bob)
      end

      should "report the completed payments on the order" do
        assert_equal 15.to_money, @invoice.reload.completed_payments_amount
      end
    end

    context "with a completed payment on the order" do
      setup do
        @payment = Payment.create!(:account => @account, :payment_method => "check", :amount => 15.to_money)
        @payment.payables << Payable.new(:subject => @order, :amount => 15.to_money)
        @payment.complete!(@bob)
      end

      should "report the completed payments on the order" do
        assert_equal 15.to_money, @invoice.reload.completed_payments_amount
      end
    end
  end
end
