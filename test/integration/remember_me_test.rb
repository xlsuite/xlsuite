require File.dirname(__FILE__) + '/../test_helper'
require "action_controller/integration"

class RememberMeTest < ActionController::IntegrationTest
  def setup
    @account = Account.find(:first)
    host! @account.domains.first.name

    @sam = @account.parties.create!(:first_name => "Sam", :password => "password", :password_confirmation => "password")
    EmailContactRoute.create!(:routable => @sam, :address => "sam@bulge.net", :name => "Main")
    @sam.append_permissions(:edit_party)
  end

  def test_login_logout
    get parties_url
    assert_redirected_to new_session_path
    assert_equal parties_path, session[:return_to], "Last location recorded for posterity"

    follow_redirect!
    assert_template "sessions/new"

    post sessions_path, :user => {:email => "sam@bulge.net", :password => "password"}, :remember_me => "1"

    @sam.reload
    assert_equal @sam.token, cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN]
    assert_redirected_to parties_path

    follow_redirect!
    assert_response :success

    # Logout
    get logout_url
    assert_redirected_to dashboard_url, "Logout occured successfully\n#{response.body}"
    assert_nil @sam.reload.token, "User's token forgotten in DB"
    assert_equal "", cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN], "User's authentication cookie destroyed"
    assert_nil session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID], "User forgotten in session"
    assert_redirected_to dashboard_url
  end

  def test_login_with_remembered_cookie
    post sessions_path, :user => {:email => "sam@bulge.net", :password => "password"}, :remember_me => "1"

    @sam.reload
    assert_equal @sam.token, cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN]

    open_session do |s|
      s.cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN] = @sam.token
      s.get parties_url
      s.assert_response :success
    end
  end
end
