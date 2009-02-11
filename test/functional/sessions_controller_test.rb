require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class NewSessionsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    get :new
  end

  def test_makes_an_authenticated_user_available_for_the_view
    assert_kind_of XlSuite::AuthenticatedUser, assigns(:user)
  end

  def test_form_posts_to_create_and_has_email_password_remember_me_fields
    assert_select "form[action=?][method=post]", sessions_path do
      assert_select "input#user_email[autocomplete=on]"
      assert_select "input#user_password[type=password][autocomplete=on]"
      assert_select "input#remember_me[type=checkbox]"
      assert_select "input[type=submit][value*=?]", /login/i
    end
  end
end

class CreateSessionsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @user = stub_everything("authenticated user")
    @user.stubs(:id).returns(123)
    @user.stubs(:staff?).returns(false)
    @user.stubs(:installer?).returns(false)
    @user.stubs(:member_of?).returns(false)
  end

  def test_create_session_with_right_username_and_password
    Party.expects(:authenticate_with_email_and_password!).with("me", "pass").returns(@user)
    @controller.expects(:current_user=).with(@user)

    post :create, :user => {:email => "me", :password => "pass"}

    assert_redirected_to forum_categories_path
    assert_nil cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN]
  end

  def test_create_session_with_right_username_and_password_and_remember_me
    Party.expects(:authenticate_with_email_and_password!).with("me", "pass").returns(@user)
    cookie_value = {:value => "cookie value", :expires => 5.hours.from_now}
    @user.expects(:remember_me!).returns(cookie_value)

    post :create, :user => {:email => "me", :password => "pass"}, :remember_me => "1"

    assert_not_nil @response.cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN],
        "No :auth_token cookie in the response\n#{@response.cookies.to_yaml}"
    assert @response.cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN].include?("cookie value"),
        "Could not find cookie #{cookie_value.inspect} in #{@response.cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN].inspect}"
  end

  def test_create_session_when_unknown_user_renders_new
    Party.stubs(:authenticate_with_email_and_password!).raises(XlSuite::AuthenticatedUser::UnknownUser.new)
    post :create, :user => {:email => "me", :password => "pass"}

    assert_template "new"
  end

  def test_create_session_when_bad_authentication_renders_new
    Party.stubs(:authenticate_with_email_and_password!).raises(XlSuite::AuthenticatedUser::BadAuthentication.new)
    post :create, :user => {:email => "me", :password => "pass"}

    assert_template "new"
  end

  def test_redirects_to_stored_location
    @request.session[:return_to] = "/my/original/url?a=b&c=d"
    Party.stubs(:authenticate_with_email_and_password!).returns(@user)
    post :create, :user => {:email => "me", :password => "pass"}
    assert_redirected_to "/my/original/url?a=b&c=d"
    assert_nil session[:return_to]
  end
end

class DeleteSessionsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    Party.stubs(:find).returns(@user = mock("user"))
    @user.stubs(:archived?).returns(false)
    @user.stubs(:forget_me!)
    @user.stubs(:staff?).returns(false)
    @user.stubs(:installer?).returns(false)
    @user.stubs(:member_of?).returns(false)
    @user.stubs(:confirmation_token).returns(nil)
    @user.stubs(:find_unread_emails).returns([])
    @user.stubs(:count_unread_emails).returns(0)
    @request.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = 137
  end

  def test_user_forgotten
    @user.expects(:forget_me!)
    get :destroy
  end

  def test_session_emptied
    @controller.expects(:reset_session)
    get :destroy

    assert_redirected_to new_session_url
  end

  def test_auth_token_cookie_destroyed
    get :destroy
    
    assert_equal [], @response.cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN]
  end
end
