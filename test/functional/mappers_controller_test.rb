require File.dirname(__FILE__) + '/../test_helper'
require 'mappers_controller'

# Re-raise errors caught by the controller.
class MappersController; def rescue_action(e) raise e end; end

class MappersControllerWithNoPermissionTest < Test::Unit::TestCase
  def setup
    @controller = MappersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @account = Account.find(:first)
    login_with_no_permissions!(:bob)
  end

  def test_index
    get :index
    assert_response :success
    assert_template "index"
  end
  
  def test_create
    post :create, :mapper => {:name => "Test", :description => "Description"}, 
        :mappings => {:header_lines_count => "1", :tag_list => "mapper test", 
        :map => {"1" => {:field => "first_name", :model => "Party", :name => ""},
            "2" => {:field => "", :model => "", :name => ""},
            "3" => {:field => "email_address", :model => "EmailContactRoute", :name => "Main"},
            "4" => {:field => "", :model => "", :name => ""} }
          }
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_edit
    get :edit, :id => mappers(:empty_mapper).id
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_update
    put :update, :id => mappers(:empty_mapper).id
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_destroy
    delete :destroy, :id => mappers(:empty_mapper).id
    assert_template "shared/rescues/unauthorized"
  end
end

class MappersControllerWithRequiredPermissionTest < Test::Unit::TestCase
  def setup
    @controller = MappersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @account = Account.find(:first)
    @bob = login_with_permissions!(:bob, :edit_mappings)
  end

  def test_index
    get :index
    assert_response :success
    assert_template "index"
  end
  
  def test_create
    xhr :post, :create, :mapper => {:name => "Test", :description => "Description"}, 
        :mappings => {:header_lines_count => "1", :tag_list => "mapper test", 
        :map => {"1" => {:field => "first_name", :model => "Party", :name => ""},
            "2" => {:field => "", :model => "", :name => ""},
            "3" => {:field => "email_address", :model => "EmailContactRoute", :name => "Main"},
            "4" => {:field => "", :model => "", :name => ""} }
          },
        :import => {:id => 1}
    assert_response :success
    assert_template 'create.rjs'
  end
  
  def test_edit
    get :edit, :id => mappers(:empty_mapper).id
    assert_response :success
    assert_template "edit"
  end
  
  def test_update
    put :update, :id => mappers(:empty_mapper).id
    assert_redirected_to mappers_path
  end
  
  def test_destroy
    delete :destroy, :id => mappers(:empty_mapper).id
    assert_redirected_to mappers_path
  end
end
