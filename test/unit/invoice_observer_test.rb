require File.dirname(__FILE__) + '/../test_helper'

class InvoiceObserverTest < Test::Unit::TestCase
  def setup
    @observer = InvoiceObserver.instance
    @observer.stubs(:logger).returns(logger)

    @invoice = mock("Invoice")
  end

  context "InvoiceObserver#before_save" do
    context "with a new invoice" do
      setup do
        @invoice.stubs(:new_record?).returns(true)
      end

      should "set the status to 'New'" do
        @invoice.expects(:status=).with("New")
        @observer.before_save(@invoice)
      end
    end

    context "with an invoice whose balance is zero" do
      setup do
        @invoice.stubs(:new_record?).returns(false)
        @invoice.stubs(:paid_in_full=)
        @invoice.stubs(:status=)
        @invoice.stubs(:balance).returns(Money.zero)
      end

      should "set the status to 'Collected'" do
        @invoice.expects(:status=).with("Collected")
        @observer.before_save(@invoice)
      end

      should "set the paid_in_full flag to true" do
        @invoice.expects(:paid_in_full=).with(true)
        @observer.before_save(@invoice)
      end
    end
  end
end
