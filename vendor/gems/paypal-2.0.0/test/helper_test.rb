$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'paypal'

require_gem 'money'
require_gem 'actionpack' rescue LoadError raise(StandardErrror.new("This test needs ActionPack installed as gem to run"))


# Little hack class which pretends to be a active controller
class TestController
  include Paypal::Helpers
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::FormTagHelper

  def url_for(options, *parameters_for_method_reference)
    "http://www.sandbox.paypal.com/cgi-bin/webscr"
  end
end

class HelperTest < Test::Unit::TestCase
 
  
  def assert_inputs(options, text)
    all = text.scan(/name\=\"(\w+)\"/).flatten
    
    xor = (options.keys | all) - (options.keys & all)
    
    # xor
    assert_equal [], xor, "options do not match expectations does not have keys #{xor.inspect} only appear in one of both sides in \n\n#{text}"

    text.scan(/name\=\"([^"]+).*?value\=\"([^"]+)/) do |key, value|
      if options.has_key?(key)
        assert_equal options[key], value, "key #{key} was '#{options[key]}' and not '#{value}' in \n\n#{text}" 
      end
    end
  end
   
  def setup 
    @helpers = TestController.new
  end

  def test_paypal_form_start
    assert_equal %{<form action="http://www.sandbox.paypal.com/cgi-bin/webscr" method="post">}, @helpers.paypal_form_tag
  end

  def test_paypal_setup_with_money
    actual = @helpers.paypal_setup("100", Money.us_dollar(50000), "bob@bigbusiness.com")    
    assert_inputs({ "amount" => "500.00",
                    "business" => "bob@bigbusiness.com",
                    "charset" => "utf-8",
                    "cmd" => "_ext-enter",
                    "currency_code" => "USD",
                    "item_name" => "Store purchase",
                    "item_number" => "100",
                    "no_note" => "1",
                    "no_shipping" => "1",
                    "redirect_cmd" => "_xclick",
                    "quantity" => "1"}, actual)
  end

  def test_paypal_setup_with_money_and_tax
    actual = @helpers.paypal_setup("100", Money.us_dollar(50000), "bob@bigbusiness.com", :tax => Money.us_dollar(500))    
    assert_inputs({ "amount" => "500.00",
    "business" => "bob@bigbusiness.com",
    "charset" => "utf-8",
    "cmd" => "_ext-enter",
    "currency_code" => "USD",
    "item_name" => "Store purchase",
    "item_number" => "100",
    "no_note" => "1",
    "no_shipping" => "1",
    "quantity" => "1",
    "redirect_cmd" => "_xclick",
    "tax" => "5.00"}, actual)
  end
  
  def test_paypal_setup_with_money_and_invoice
    actual = @helpers.paypal_setup("100", Money.us_dollar(50000), "bob@bigbusiness.com", :invoice => "Cool invoice!")    
    assert_inputs({ "amount" => "500.00",
    "business" => "bob@bigbusiness.com",
    "charset" => "utf-8",
    "cmd" => "_ext-enter",
    "currency_code" => "USD",
    "invoice" => "Cool invoice!",
    "item_name" => "Store purchase",
    "item_number" => "100",
    "no_note" => "1",
    "no_shipping" => "1",
    "redirect_cmd" => "_xclick",
    "quantity" => "1"}, actual)
  end  

  def test_paypal_setup_with_money_and_custom
    actual = @helpers.paypal_setup("100", Money.us_dollar(50000), "bob@bigbusiness.com", :custom => "Custom")    
    assert_inputs({ "amount" => "500.00",
    "business" => "bob@bigbusiness.com",
    "charset" => "utf-8",
    "cmd" => "_ext-enter",
    "currency_code" => "USD",
    "custom" => "Custom",
    "item_name" => "Store purchase",
    "item_number" => "100",
    "no_note" => "1",
    "no_shipping" => "1",
    "quantity" => "1", 
    "redirect_cmd" => "_xclick",
    }, actual)
  end  
  
    def test_paypal_setup_with_float
      actual = @helpers.paypal_setup("100", 50.00, "bob@bigbusiness.com", :currency => 'CAD')
      assert_inputs({ "amount" => "50.00",
      "business" => "bob@bigbusiness.com",
      "charset" => "utf-8",
      "cmd" => "_ext-enter",
      "currency_code" => "CAD",
      "item_name" => "Store purchase",
      "item_number" => "100",
      "no_note" => "1",
      "no_shipping" => "1",
      "redirect_cmd" => "_xclick",
      "quantity" => "1"}, actual)
    end

    def test_paypal_setup_with_string
      actual = @helpers.paypal_setup("100", "50.00", "bob@bigbusiness.com", :currency => 'CAD')
      assert_inputs({ "amount" => "50.00",
      "business" => "bob@bigbusiness.com",
      "charset" => "utf-8",
      "cmd" => "_ext-enter",
      "currency_code" => "CAD",
      "item_name" => "Store purchase",
      "item_number" => "100",
      "no_note" => "1",
      "no_shipping" => "1",
      "redirect_cmd" => "_xclick",
      "quantity" => "1"}, actual)
    end
    
  def test_paypal_setup_options
    actual = @helpers.paypal_setup("100", Money.us_dollar(100), "bob@bigbusiness.com", :item_name => "MegaBob's shop purchase", :return => 'http://www.bigbusiness.com', :cancel_return => 'http://www.bigbusiness.com', :notify_url => 'http://www.bigbusiness.com', :no_shipping => 0, :no_note => 0  )    
    assert_inputs({ "amount" => "1.00",
    "business" => "bob@bigbusiness.com",
    "cancel_return" => "http://www.bigbusiness.com",
    "charset" => "utf-8",
    "cmd" => "_ext-enter",
    "currency_code" => "USD",
    "item_name" => "MegaBob's shop purchase",
    "item_number" => "100",
    "no_note" => "0",
    "no_shipping" => "0",
    "notify_url" => "http://www.bigbusiness.com",
    "quantity" => "1",
    "redirect_cmd" => "_xclick",
    "return" => "http://www.bigbusiness.com"}, actual )
  end    


end
