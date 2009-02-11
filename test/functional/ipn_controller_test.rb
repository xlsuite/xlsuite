require File.dirname(__FILE__) + '/../test_helper'
require 'ipn_controller'

# Re-raise errors caught by the controller.
class IpnController; def rescue_action(e) raise e end; end

class IpnControllerTest < Test::Unit::TestCase
  def setup
    @controller = IpnController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
