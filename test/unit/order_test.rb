require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < Test::Unit::TestCase
  context "An order with an invoice" do
    setup do
      @order = create_order

      @invoice = accounts(:wpul).invoices.build(:order => @order, :date => Date.today, :customer => parties(:bob))
      @invoice.save(false)
    end

    should "nullify the association to the invoice when it is destroyed" do
      @order.destroy
      assert_nil @invoice.reload.order
    end
  end
  
  context "Making payment to an order" do
    setup do
      @order = create_order
      @order.lines.create!(:quantity => 2, :retail_price => Money.new(1500), :product => Product.find(:first))
      assert_equal false, @order.paid_in_full?
    end

    context "using Paypal" do
      setup do
        @payment_method = "paypal"
      end

      context "that has been paid in full" do
        setup do
          @payment = @order.make_payment!(@payment_method)
          @payable = Payable.find_by_payment_id(@payment.id)
          assert_equal false, @order.paid_in_full?
          PaymentHelper.new.complete!(@payable, parties(:bob))
          assert_equal true, @order.paid_in_full?
        end

        should "raise HasBeenPaidInFull exception when trying to start the payment" do
          assert_raise XlSuite::PaymentSystem::HasBeenPaidInFull do
            @payment.start!(parties(:bob))
          end
        end
        
        should "raise HasBeenPaidInFull exception when trying to create another payment" do
          assert_raise XlSuite::PaymentSystem::HasBeenPaidInFull do
            @order.make_payment!(@payment_method)
          end
        end
      end
    end
  end
  
  context "Generating an invoice from an order" do
    setup do    
      @order = accounts(:wpul).orders.create!(:invoice_to => parties(:bob), :date => Time.now)
      @order.lines.create!(:product => products(:fish), :quantity => 5.0)
      @order.lines.create!(:description => "Fish shipping fee is free", :comment => "You do not need to pay for fish shipping fee")
      @order.lines.create!(:product => products(:dog), :quantity => 1.0)
      @order.reload

      @invoice = @order.generate_new_invoice!
    end
    
    should "create the invoice correctly" do
      assert_equal 3, @invoice.lines.count
      assert_equal @order.balance, @invoice.balance
    end
    
    should "set the order lines quantity invoiced" do
      @order.lines.each do |ol|
        assert_equal ol.quantity, ol.quantity_invoiced
      end
    end
    
    context "after an invoice has been generated" do
      context "and no change has been made" do
        should "raise an exception" do 
          assert_raise XlSuite::PaymentSystem::HasNotBeenModified do
            @new_invoice = @order.generate_new_invoice!
          end
        end
      end
      
      context "with changes made to the order lines" do
        setup do
          ol = @order.lines.first
          ol.update_attribute(:quantity, BigDecimal.new("2.0"))
          @order.lines.create!(:product => products(:rabbit), :quantity => 2.0)
          @order.reload
          
          @new_invoice = @order.generate_new_invoice!
        end
        
        should "generate the new invoice correcty" do
          assert_equal 2, @new_invoice.lines.count
        end
      end
      
      context "with changes only on payment" do
        setup do
          order_balance = @order.balance
          puts order_balance.inspect
          payment = accounts(:wpul).payments.create!(:amount => Money.new(1500), :payment_method => "cash")
          payable = Payable.create!(:payment => payment, :subject => @order)
          payment.capture_payment!
          assert_equal order_balance - Money.new(1500), @order.reload.balance
          
          @new_invoice = @order.generate_new_invoice!
        end
        
        should "not contain any invoice line" do
          assert_equal 0, @new_invoice.lines.count
        end
        
        should "reduce the balance on the invoice" do
          assert_equal @order.reload.balance, @new_invoice.balance
        end
      end
    end
  end
end
