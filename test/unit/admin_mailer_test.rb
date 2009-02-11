require File.dirname(__FILE__) + "/../test_helper"

class AdminMailerTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.deliveries = @mails = []
    @account = accounts(:wpul)
  end

  context "A new order with two lines" do
    setup do
      @comment_line = stub("comment_order_line", :description => "this is a description", :retail_price => nil, :quantity => nil, :extension_price => nil)
      @product_line = stub("product_order_line", :description => "Fish", :quantity => 10, :retail_price => "23.99 USD".to_money, :extension_price => "239.90 USD".to_money)

      @order = stub("order", :account => @account, :lines => [@comment_line, @product_line], :number => "20080001", :id => "1")
      @order.stubs(:invoice_to).returns(stub("party", :name => Name.new("John", "Kennedy", "F"), :id => 902))
      @order.stubs(:ship_to).returns(stub("address_contact_route", :line1 => "200 Privet Dr", :city => "Hampton", :state => "NJ", :country => "US", :zip => "90210"))
    end

    should "have a REAL account" do
      assert_not_nil @account
    end

    should "have an account" do
      assert_equal @account, @order.account
    end

    context "on notification" do
      setup do
        AdminMailer.deliver_new_order(:order => @order, :recipients => "bob@test.com", :customer => :bob)
        @mail = @mails.first
      end

      should "mention the customer name's on the order" do
        assert_include @order.invoice_to.name.to_s, @mail.body
      end

      should "link to the order" do
        assert_include "http://#{@account.domain_name}/admin/orders/#{@order.id}", @mail.body
      end
    end
  end
end
