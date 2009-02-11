require File.dirname(__FILE__) + '/../test_helper'
require 'providers_controller'

# Re-raise errors caught by the controller.
class ProvidersController; def rescue_action(e) raise e end; end

class ProvidersControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProvidersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
