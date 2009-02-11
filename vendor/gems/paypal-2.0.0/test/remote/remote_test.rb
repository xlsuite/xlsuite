$:.unshift(File.dirname(__FILE__) + '/../../lib')

require 'test/unit'
require 'paypal'

class RemoteTest < Test::Unit::TestCase

  def test_raw
    Paypal::Notification.ipn_url = "https://www.sandbox.paypal.com/cgi-bin/webscr"
    @paypal = Paypal::Notification.new('')
    
    assert_nothing_raised do
      assert_equal false, @paypal.acknowledge    
    end
  end
end
