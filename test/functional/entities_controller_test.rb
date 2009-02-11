require File.dirname(__FILE__) + '/../test_helper'
require 'entities_controller'

# Re-raise errors caught by the controller.
class EntitiesController; def rescue_action(e) raise e end; end

class EntitiesControllerTest < Test::Unit::TestCase
  def setup
    @controller = EntitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
