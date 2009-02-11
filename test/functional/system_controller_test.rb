require File.dirname(__FILE__) + '/../test_helper'
require 'system_controller'

# Re-raise errors caught by the controller.
class SystemController; def rescue_action(e) raise e end; end

class SystemControllerTest < Test::Unit::TestCase
  def setup
    @controller = SystemController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
