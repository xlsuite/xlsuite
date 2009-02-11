require File.dirname(__FILE__) + '/../test_helper'
require 'filter_controller'

# Re-raise errors caught by the controller.
class FilterController; def rescue_action(e) raise e end; end

class FilterControllerTest < Test::Unit::TestCase
  def setup
    @controller = FilterController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
