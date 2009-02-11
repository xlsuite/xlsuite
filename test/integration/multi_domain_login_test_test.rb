require "#{File.dirname(__FILE__)}/../test_helper"

class MultiDomainLoginTestTest < ActionController::IntegrationTest
  def setup
    @account0 = Account.new(:title => "Sell FM.com")
    @account0.expires_at = 15.minutes.from_now
    @account0.save!
    @account0.domains.create!(:name => "sellfm.com")

    @party0 = @account0.parties.create!(:first_name => "rick", :password => "password", :password_confirmation => "password")
    @email0 = @party0.main_email

    @account1 = Account.new(:title => "We Put Up Lights.com")
    @account1.expires_at = 15.minutes.from_now
    @account1.save!
    @account1.domains.create!(:name => "weputuplights.com")

    @party1 = @account1.parties.create!(:first_name => "rick", :password => "password", :password_confirmation => "password")
    @email1 = @party1.main_email
  end

  def test_same_email_on_multi_domains_allows_login
    @email0.update_attributes!(:address => "rick@gmail.com")
    @email1.update_attributes!(:address => "rick@gmail.com")

    open_session do |s|
      s.host! @account0.domains.first.name
      s.get new_session_path
      s.post sessions_path, :user => {:email => @email0.address, :password => "password"}
      s.assert_equal @party0.id, s.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID]
    end

    open_session do |s|
      s.host! @account1.domains.first.name
      s.get new_session_path
      s.post sessions_path, :user => {:email => @email1.address, :password => "password"}
      s.assert_equal @party1.id, s.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID]
    end
  end

  def test_different_emails_on_different_domains_dont_allow_cross_login
    @email0.update_attributes!(:address => "rick@sellfm.com")
    @email1.update_attributes!(:address => "rick@weputuplights.com")

    # Check login rick@weputuplights.com on sellfm.com fails
    open_session do |s|
      s.host! @account0.domains.first.name
      s.get new_session_path
      s.post sessions_path, :user => {:email => @email1.address, :password => "password"}
      s.assert_response :success
      s.assert_template "sessions/new"
    end

    # Check login rick@sellfm.com on weputuplights.com fails
    open_session do |s|
      s.host! @account1.domains.first.name
      s.get new_session_path
      s.post sessions_path, :user => {:email => @email0.address, :password => "password"}
      s.assert_response :success
      s.assert_template "sessions/new"
    end
  end
end
