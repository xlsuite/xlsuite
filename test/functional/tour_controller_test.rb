require File.dirname(__FILE__) + '/../test_helper'
require 'tour_controller'

# Re-raise errors caught by the controller.
class TourController; def rescue_action(e) raise e end; end

class TourControllerTest < Test::Unit::TestCase
  def setup
    @controller = TourController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_details
    get :details, :id => AddressContactRoute.find(:first).id
  end
end
