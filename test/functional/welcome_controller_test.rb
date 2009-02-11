require File.dirname(__FILE__) + '/../test_helper'
require 'welcome_controller'

# Re-raise errors caught by the controller.
class WelcomeController; def rescue_action(e) raise e end; end

class WelcomeControllerTest < Test::Unit::TestCase
  def setup
    @controller = WelcomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_links
    get :links
    assert_response :success
    assert_not_nil assigns(:links)
    assert_template 'links'
  end
  
  def test_get_create_link
    get :create_link
    assert_template 'create_link'    
  end
  
  def test_post_create_link
    post :create_link, :link => {:title => "test", :address => 'www.google.ca',
      :reciprocal_address => 'http://softwaredev.meetup.com/17/members/2218687/'}
    assert_redirected_to :controller => 'welcome', :action => 'links'
  end

  def test_visiting_link_for_unknown_domain_doesnt_crash
    @request.host = "my.simple.host"
    get :index
    assert_response :missing
    assert_template "accounts/new"
  end
end
