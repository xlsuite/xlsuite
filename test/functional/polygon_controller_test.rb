require File.dirname(__FILE__) + '/../test_helper'
require 'polygons_controller'

# Re-raise errors caught by the controller.
class PolygonsController; def rescue_action(e) raise e end; end

class PolygonsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PolygonsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @bob = login_with_permissions!(:bob, :edit_party_security)
    @polygon = accounts(:wpul).polygons.create!(:points => [[1,1],[2,2],[1,2]])
  end
  
  def test_can_create_polygon
    assert_difference Polygon, :count, 1 do
      post :create, :polygon => {:points => "[[1.2,3],[5,-6], [-.23,9]]", :name => "First polygon", 
                                 :description => "This is the Strathcona area"}, :format => "js"
    end
    assert_response :success
  end
  
  def test_can_update_polygon
    post :update, :id => @polygon.id, :polygon => {:points => "[[4,3],[2,1],[8,9]]", :name => "Updated polygon", 
                               :description => "This is a polygon"}, :format => "js"
    assert_equal [[4,3],[2,1],[8,9]], accounts(:wpul).polygons.find(@polygon.id).points
  end
  
  def test_can_delete_polygon
    assert_difference Polygon, :count, -1 do
      post :destroy, :id => @polygon.id, :format => "js"
    end
    assert_response :success
  end
end