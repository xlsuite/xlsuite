require File.dirname(__FILE__) + '/../test_helper'
require 'sale_event_items_controller'

# Re-raise errors caught by the controller.
class SaleEventItemsController; def rescue_action(e) raise e end; end

class SaleEventItemsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SaleEventItemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
