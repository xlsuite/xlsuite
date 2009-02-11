require File.dirname(__FILE__) + '/../test_helper'
require 'payables_controller'

# Re-raise errors caught by the controller.
class PayablesController; def rescue_action(e) raise e end; end

class PayablesControllerTest < Test::Unit::TestCase
  def setup
    @controller = PayablesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
