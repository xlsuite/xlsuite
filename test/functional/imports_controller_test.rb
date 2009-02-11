require File.dirname(__FILE__) + '/../test_helper'
require 'imports_controller'

# Re-raise errors caught by the controller.
class ImportsController; def rescue_action(e) raise e end; end

class LoggedInWithImporPermissionsImportsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ImportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @account = Account.find(:first)
    @bob = login_with_permissions!(:bob, :allow_importing, :edit_imports)
  end

  def test_get_index
    get :index
    assert_response :success
    assert_template "index"
  end
  
  def test_get_new
    get :new
    assert_response :success
    assert_template "new"
  end
  
  def test_post_create
    assert_difference Import, :count, 1 do
      post :create, :import => {:file => fixture_file_upload('/files/card_scanner.csv')}
      import = assigns(:import)
      assert_not_nil import.csv
      assert_equal import.party.id, parties(:bob).id
      assert_equal import.account.id, @account.id
      assert_redirected_to edit_import_path(import)
    end
  end
  
  def test_destroy
    assert_difference Import, :count, -1 do
      get :destroy, :id => imports(:no_data)
      assert_redirected_to :action => "index"
    end
  end
  
  def test_edit_normal_request
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    get :edit, :id => import.id
    assert_response :success
    assert_template "edit"
  end
  
  def test_edit_xhr
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    xhr :get, :edit, :id => import.id
    assert_response :success
    assert_template "edit.rjs"
  end
  
  def test_go
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    post :go, :id => imports(:bia_contacts).id, :mappings => {}
    assert_redirected_to summary_import_path(imports(:bia_contacts))
  end

  def test_save_xhr
    xhr :post, :save, :id => imports(:bia_contacts).id, :mappings => {}
    assert_response :success
    assert_template "save.rjs"
  end
  
  def test_summary
    get :summary, :id => imports(:bia_contacts).id
    assert_response :success
    assert_template "summary"
  end
end

class LoggedInWithEditImportPermissionOnlyImportsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ImportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @account = Account.find(:first)
    @bob = login_with_permissions!(:bob, :edit_imports)
  end
  
  def test_go
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    post :go, :id => imports(:bia_contacts).id, :mappings => {}
    assert_template "shared/rescues/unauthorized"
  end
end

class LoggedInWithNoPermissionImportsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ImportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @account = Account.find(:first)
    @bob = login_with_no_permissions!(:bob)
  end
  
  def test_get_index
    get :index
    assert_response :success
    assert_template "index"
  end
  
  def test_get_new
    get :new
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_post_create
    assert_difference Import, :count, 0 do
      post :create, :import => {:file => fixture_file_upload('/files/card_scanner.csv')}
      assert_template "shared/rescues/unauthorized"
    end
  end
  
  def test_destroy
    assert_difference Import, :count, 0 do
      get :destroy, :id => imports(:no_data)
      assert_template "shared/rescues/unauthorized"
    end
  end
  
  def test_edit_normal_request
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    get :edit, :id => import.id
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_edit_xhr
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    xhr :get, :edit, :id => import.id
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_go
    import = imports(:bia_contacts)
    import.file = fixture_file_upload('/files/BIA_contacts_short.csv')
    import.save!
    post :go, :id => imports(:bia_contacts).id, :mappings => {}
    assert_template "shared/rescues/unauthorized"
  end

  def test_save_xhr
    xhr :post, :save, :id => imports(:bia_contacts).id, :mappings => {}
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_summary
    get :summary, :id => imports(:bia_contacts).id
    assert_response :success
    assert_template "summary"
  end
end