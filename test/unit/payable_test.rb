require File.dirname(__FILE__) + '/../test_helper'

class PayableTest < Test::Unit::TestCase
  def setup
    @account = accounts(:wpul)
    @invoice = invoices(:johns_invoice)
    @customer = @invoice.customer
  end

  context "A payable" do
    setup do
      @payable = Payable.new(:account => @account)
    end

    should "refer to an account" do
      assert_nothing_raised do
        @payable.account = @account
      end
    end

    should "refer to a payment" do
      assert_nothing_raised do
        @payable.payment = @payment
      end
    end

    should "refer to a subject" do
      assert_nothing_raised do
        @payable.subject = @invoice
      end
    end

    should "have an amount" do
      assert_nothing_raised do
        @payable.amount = "1200.00 usd".to_money
      end
    end

    should "accept a String amount" do
      @payable.amount = "1220 cad"
      @payable.save(false)
      assert_equal "1220 CAD".to_money, @payable.reload.amount
    end

    should "be invalid when assigned a voided subject" do
      @invoice.void!(parties(:bob))
      @payable.subject = @invoice
      deny @payable.valid?, "Payable should be invalid"
      assert_not_nil @payable.errors.on(:subject), "Payable should have an error on Subject: #{@payable.errors.full_messages.join(", ")}"
    end
  end

  context "An existing payable that is voided" do
    setup do
      @payable = payables(:peters_payment_on_invoice_20051023)
      @payable.void!(parties(:bob))
      @payable.reload
    end

    should "set the voided_at column" do
      assert_not_nil @payable.voided_at
    end

    should "set the voided_by column" do
      assert_equal parties(:bob), @payable.voided_by
    end

    should "set the voided_by_name column" do
      assert_equal parties(:bob).name.to_s, @payable.voided_by_name
    end

    should "respond true to #void?" do
      assert @payable.void?
    end
  end
end
