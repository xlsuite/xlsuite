require File.dirname(__FILE__) + '/../test_helper'
require 'layouts_controller'

# Re-raise errors caught by the controller.
class LayoutsController; def rescue_action(e) raise e end; end

class LayoutsControllerTest < Test::Unit::TestCase
  def setup
    @controller = LayoutsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @controller.stubs(:current_account).returns(@account = mock("account"))
    @account.stubs(:expired?).returns(false)
    @account.stubs(:nearly_expired?).returns(false)
    @account.stubs(:layouts).returns(@layouts_proxy = mock("layouts proxy"))
    @account.stubs(:pages).returns(@pages_proxy = mock("pages proxy"))
    @account.stubs(:groups).returns(@groups_proxy = mock("groups proxy"))
    @groups_proxy.stubs(:find).returns([])

    Party.stubs(:find).returns(@admin = Party.new)
    @admin.stubs(:can?).returns(true)
    @admin.stubs(:login).returns("simon")
    @admin.stubs(:id).returns(320)

    @request.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = 932

    @layout = Layout.new {|l| l.id = 2112; l.title = "Main"}
  end

  def test_should_get_index
    @layouts_proxy.expects(:find_all_by_title).returns([Layout.new {|l| l.id = 324; l.title = "Basic"}])

    get :index

    assert_response :success
    assert assigns(:layouts)
  end

  def test_should_get_new
    @layouts_proxy.expects(:build).returns(Layout.new)

    get :new

    assert_response :success
    assert assigns(:layout)
  end
  
  def test_should_create_layout
    @layouts_proxy.expects(:build).with({ :title => "abc", :content_type => "text/html",
        :encoding => "UTF-8", :body => "{{ page.body }}" }.stringify_keys).returns(@layout = Layout.new)
    @layout.expects(:save).returns(true)

    post :create, :layout => { :title => "abc", :content_type => "text/html",
        :encoding => "UTF-8", :body => "{{ page.body }}" }
    
    assert_redirected_to layouts_path
  end

  def test_should_get_edit
    @layouts_proxy.expects(:find).with("1").returns(@layout)

    get :edit, :id => 1

    assert_response :success
  end
  
  def test_should_update_layout
    @layouts_proxy.expects(:find).with("1").returns(@layout)
    @layout.expects(:update_attributes).with("title" => "abc").returns(true)

    put :update, :id => 1, :layout => { :title => "abc" }

    assert_redirected_to layouts_path
  end
  
  def test_should_destroy_layout
    @layouts_proxy.expects(:find).with("1").returns(@layout)
    @layout.expects(:destroy)

    delete :destroy, :id => 1

    assert_redirected_to layouts_path
  end
end
