require File.dirname(__FILE__) + '/../../test_helper'

module XlSuite
  module AuthenticatedSystemTest
    class MockControllerBase
      def self.helper_method(*args); end
      def self.before_filter(*args); end
      def self.hide_action(*args); end
      def self.logger; RAILS_DEFAULT_LOGGER; end

      def logger
        self.class.logger
      end

      def index; end
      def new; end
      def create; end
    end

    class AuthenticatedSystemLoginRequiredFilterAndProtectedTest < Test::Unit::TestCase
      def setup
        class << @controller = MockControllerBase.new
          include XlSuite::AuthenticatedSystem
        end

        @controller.stubs(:protected?).returns(true)
        @controller.stubs(:action_name).returns("new")
        @controller.stubs(:respond_to?).returns(true)
      end

      def test_calls_access_denied_when_protected_and_unauthorized
        @controller.stubs(:current_user?).returns(false)
        @controller.stubs(:authorized?).returns(false)
        @controller.expects(:access_denied).returns(false)
        assert_equal false, @controller.login_required
      end

      def test_lets_request_through_when_protected_unauthenticated_and_unauthorized
        @controller.stubs(:current_user?).returns(false)
        @controller.stubs(:authorized?).returns(true)
        assert_not_equal false, @controller.login_required
      end

      def test_does_not_call_access_denied_when_protected_and_authorized
        @controller.stubs(:current_user?).returns(true)
        @controller.stubs(:authorized?).returns(true)
        assert_not_equal false, @controller.login_required
      end
    end

    class AuthenticatedSystemStoreLocationTest < Test::Unit::TestCase
      def setup
        class << @controller = MockControllerBase.new
          include XlSuite::AuthenticatedSystem
        end

        @controller.stubs(:session).returns(@session = Hash.new)
        @controller.stubs(:request).returns(@request = mock("request"))
        @controller.stubs(:action_name).returns("new")
        @controller.stubs(:respond_to?).returns(true)
        @request.stubs(:env).returns(@env = mock("env"))
        @request.stubs(:xhr?).returns(false)
      end

      def test_stores_location
        @env.stubs(:[]).with("REQUEST_URI").returns(:request_uri)
        @session.expects(:[]=).with(:return_to, :request_uri)
        @controller.store_location
      end
    end

    
    class AuthenticatedSystemLoginRequiredFilterAndNotProtectedTest < Test::Unit::TestCase
      def setup
        class << @controller = MockControllerBase.new
          include XlSuite::AuthenticatedSystem
        end

        @controller.stubs(:protected?).returns(false)
        @controller.stubs(:action_name).returns("new")
        @controller.stubs(:respond_to?).returns(true)
      end

      def test_lets_request_through_when_user_present
        @controller.stubs(:current_user?).returns(true)
        @controller.stubs(:current_user).returns(@user = mock("user"))
        assert_not_equal false, @controller.login_required
      end

      def test_lets_request_through_when_anonymous
        @controller.stubs(:current_user?).returns(false)
        assert_not_equal false, @controller.login_required
      end
    end

    class AuthenticatedSystemCurrentUserTest < Test::Unit::TestCase
      def setup
        class << @controller = MockControllerBase.new
          include XlSuite::AuthenticatedSystem
        end

        @controller.stubs(:session).returns(@session = Hash.new)
      end

      def test_current_user_predicate_asserts_that_user_id_in_session
        @session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = 141
        assert @controller.current_user?
      end

      def test_current_user_predicate_asserts_that_user_id_not_in_session
        @session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = nil
        deny @controller.current_user?
      end

      def test_current_user_reader_asks_database_first_time_around
        @session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = 827
        Party.expects(:find).with(827).returns(user = stub_everything("user"))
        assert_same user, @controller.current_user
      end

      def test_current_user_raises_unknown_user_when_party_archived
        @session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = 621
        Party.expects(:find).with(621).returns(user = mock("user"))
        user.expects(:archived?).returns(true)
        assert_raises(XlSuite::AuthenticatedUser::UnknownUser) do
          @controller.current_user
        end
      end

      def test_assign_to_current_user_updates_session
        user = stub_everything("user")
        user.stubs(:id).returns(578)
        @controller.current_user = user
        assert_same user, @controller.current_user
        assert_equal 578, @controller.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID]
      end

      def test_reading_current_user_when_none_recorded_should_return_stub_user
        @session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = nil
        user = @controller.current_user
        assert_respond_to user, :can?, "Stubbed out user should respond_to?(:can?)"
        deny user.can?(:admin_forum), "Stubbed out user should always respond false to can?"
      end
    end

    class AuthenticatedSystemAuthorizationTest < Test::Unit::TestCase
      class Controller < MockControllerBase
        include XlSuite::AuthenticatedSystem
      end

      def setup
        @controller = Controller.new

        @controller.stubs(:session).returns(@session = Hash.new)
        @controller.stubs(:action_name).returns("create")
        @controller.stubs(:current_user?).returns(true)
        @controller.stubs(:current_user).returns(@user = mock("user"))
      end

      def test_wide_open_lets_any_action_go_through
        @controller.class.required_permissions :none
        assert @controller.authorized?
      end

      def test_list_of_permissions_only
        @user.expects(:can?).with([:edit_catalog, :edit_party, {:all => true}]).returns(true)
        @controller.class.required_permissions [:edit_catalog, :edit_party, {:all => true}]
        assert @controller.authorized?
      end

      def test_protect_single_action_with_permissions
        @user.expects(:can?).with(:edit_party).returns(false)
        @controller.class.required_permissions :create => :edit_party
        deny @controller.authorized?
      end

      def test_protect_using_string_code
        @controller.expects(:current_user?).returns(true)
        @controller.class.required_permissions :create => "current_user?"
        assert @controller.authorized?
      end

      def test_protect_array_of_actions_with_permissions
        @user.stubs(:can?).with(:edit_party).returns(true)
        @controller.class.required_permissions %w(new edit create update) => :edit_party

        @controller.stubs(:action_name).returns("index")
        deny @controller.authorized?

        @controller.stubs(:action_name).returns("new")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("create")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("edit")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("update")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("destroy")
        deny @controller.authorized?
      end

      def test_protect_action_with_complex_permissions
        @user.expects(:can?).with([:destroy_party, :party_admin, {:any => true}]).at_least_once.returns(true)
        @controller.class.required_permissions /destroy/ => [:destroy_party, :party_admin, {:any => true}]

        @controller.stubs(:action_name).returns("destroy")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("destroy_party")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("chitz_destroy")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("chug")
        deny @controller.authorized?
      end

      def test_auto_authorize_single_action
        @controller.class.required_permissions "index" => true

        @controller.stubs(:action_name).returns("index")
        assert @controller.authorized?

        @controller.stubs(:action_name).returns("new")
        deny @controller.authorized?
      end

      def test_auto_deny_single_action
        @controller.class.required_permissions "index" => false

        @controller.stubs(:action_name).returns("index")
        deny @controller.authorized?

        @controller.stubs(:action_name).returns("new")
        deny @controller.authorized?
      end
    end

    class AuthenticatedSystemCookieAuthenticationTest < Test::Unit::TestCase
      def setup
        class << @controller = MockControllerBase.new
          include XlSuite::AuthenticatedSystem
        end

        @user = mock("user")
        @user.stubs(:account).returns(:account)
        @controller.stubs(:cookies).returns(@cookies = Hash.new)
        @controller.stubs(:current_user?).returns(false)
        @controller.stubs(:current_account).returns(:account)
      end

      def test_starts_session_with_new_user
        @cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN] = :valid_token
        Party.expects(:authenticate_with_token!).with(:valid_token).returns(@user)
        @controller.expects(:current_user=).with(@user)

        assert_not_equal false, @controller.login_from_cookie
      end

      def test_allows_request_through_when_no_cookie
        assert_not_equal false, @controller.login_from_cookie
      end

      def test_calls_access_denied_when_auth_token_expired
        @cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN] = :expired_token
        Party.expects(:authenticate_with_token!).with(:expired_token).raises(XlSuite::AuthenticatedUser::TokenExpired.new)
        @controller.expects(:access_denied).returns(false)
        assert_equal false, @controller.login_from_cookie
      end

      def test_calls_access_denied_when_auth_token_invalid
        @cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN] = :invalid_token
        Party.expects(:authenticate_with_token!).with(:invalid_token).raises(XlSuite::AuthenticatedUser::UnknownUser.new)
        @controller.expects(:access_denied).returns(false)
        assert_equal false, @controller.login_from_cookie
      end

      def test_does_not_authenticate_if_currently_logged_in
        @controller.stubs(:current_user?).returns(false)
        assert_not_equal false, @controller.login_from_cookie
      end
    end

    class AuthenticatedSystemConfirmationTest < Test::Unit::TestCase
      class Controller < MockControllerBase
        include XlSuite::AuthenticatedSystem
      end

      def setup
        @controller = Controller.new

        @controller.stubs(:current_user?).returns(true)
        @controller.stubs(:current_user).returns(@user = mock("user"))
        @user.stubs(:id).returns(901)
      end

      def test_confirmed_user
        @user.stubs(:confirmation_token).returns(nil)
        assert @controller.reject_unconfirmed_user
      end

      def test_unconfirmed_user
        @user.stubs(:confirmation_token).returns("abcdefghij")
        @controller.expects(:flash_failure)
        @controller.expects(:confirm_party_path).with(:id => @user.id, :code => @user.confirmation_token).returns(:confirm_party_url)
        @controller.expects(:redirect_to).with(:confirm_party_url)
        deny @controller.reject_unconfirmed_user
      end    
    end    
  end
end
