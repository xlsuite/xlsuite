require File.dirname(__FILE__) + '/../test_helper'
require 'opt_outs_controller'

# Re-raise errors caught by the controller.
class OptOutsController; def rescue_action(e) raise e end; end

class OptOutsControllerTest < Test::Unit::TestCase
  def setup
    @controller = OptOutsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
