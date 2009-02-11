$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'openssl'
require 'net/http'
require File.dirname(__FILE__) + '/mocks/method_mock'
require 'test/unit'
require 'paypal'

$paypal_success = Class.new do
  def body; "VERIFIED"; end
end

$paypal_failure = Class.new do
  def body; "INVALID"; end
end


class NotificationTest < Test::Unit::TestCase

  def setup
    Paypal::Notification.ipn_url = "http://www.paypal.com/some/address"

    @paypal = Paypal::Notification.new(http_raw_data)
  end

  def test_raw
    assert_equal http_raw_data, @paypal.raw
  end

  def test_parse
    @paypal = Paypal::Notification.new(http_raw_data)
    assert_equal "500.00", @paypal.params['mc_gross']
    assert_equal "confirmed", @paypal.params['address_status']
    assert_equal "EVMXCLDZJV77Q", @paypal.params['payer_id']
    assert_equal "Completed", @paypal.params['payment_status']    
    assert_equal CGI.unescape("15%3A23%3A54+Apr+15%2C+2005+PDT"), @paypal.params['payment_date']
    # ...
  end

  def test_accessors
    assert @paypal.complete?
    assert_equal "Completed", @paypal.status
    assert_equal "6G996328CK404320L", @paypal.transaction_id
    assert_equal "web_accept", @paypal.type
    assert_equal "500.00", @paypal.gross
    assert_equal "15.05", @paypal.fee
    assert_equal "CAD", @paypal.currency
  end

  def test_compositions
    assert_equal Money.ca_dollar(50000), @paypal.amount
  end

  def test_acknowledgement    
        
    
    Net::HTTP.mock_methods( :request => Proc.new { |r, b| $paypal_success.new } ) do     
      assert @paypal.acknowledge        
    end

    Net::HTTP.mock_methods( :request => Proc.new { |r, b| $paypal_failure.new } ) do 
      assert !@paypal.acknowledge
    end

  end

  def test_send_acknowledgement
    request, body = nil
    
    Net::HTTP.mock_methods( :request => Proc.new { |r, b| request = r; body = b; $paypal_success.new } ) do     
      assert @paypal.acknowledge        
    end

    assert_equal '/some/address?cmd=_notify-validate', request.path
    assert_equal http_raw_data, body
  end

  private

  def http_raw_data
    "mc_gross=500.00&address_status=confirmed&payer_id=EVMXCLDZJV77Q&tax=0.00&address_street=164+Waverley+Street&payment_date=15%3A23%3A54+Apr+15%2C+2005+PDT&payment_status=Completed&address_zip=K2P0V6&first_name=Tobias&mc_fee=15.05&address_country_code=CA&address_name=Tobias+Luetke&notify_version=1.7&custom=&payer_status=unverified&business=tobi%40leetsoft.com&address_country=Canada&address_city=Ottawa&quantity=1&payer_email=tobi%40snowdevil.ca&verify_sign=AEt48rmhLYtkZ9VzOGAtwL7rTGxUAoLNsuf7UewmX7UGvcyC3wfUmzJP&txn_id=6G996328CK404320L&payment_type=instant&last_name=Luetke&address_state=Ontario&receiver_email=tobi%40leetsoft.com&payment_fee=&receiver_id=UQ8PDYXJZQD9Y&txn_type=web_accept&item_name=Store+Purchase&mc_currency=CAD&item_number=&test_ipn=1&payment_gross=&shipping=0.00"
  end  
end
