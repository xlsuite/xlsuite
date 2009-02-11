require File.dirname(__FILE__) + '/../test_helper'
require 'sale_events_controller'

# Re-raise errors caught by the controller.
class SaleEventsController; def rescue_action(e) raise e end; end

class SaleEventsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SaleEventsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
