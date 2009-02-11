require File.dirname(__FILE__) + '/../test_helper'
require 'suppliers_controller'

# Re-raise errors caught by the controller.
class SuppliersController; def rescue_action(e) raise e end; end

class SuppliersControllerTest < Test::Unit::TestCase
  def setup
    @controller = SuppliersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
