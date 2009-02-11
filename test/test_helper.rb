ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'francois_beausoleil/flash_helper_plugin/assertions'
require "mocha"
require File.dirname(__FILE__) + "/model_builder"

gem "thoughtbot-shoulda", ">= 2.0.5"
require "shoulda/rails"

class Test::Unit::TestCase
  include FrancoisBeausoleil::FlashHelperPlugin::Assertions
  include ModelBuilder unless ancestors.include?(ModelBuilder)

  # Load all fixture data from the Rakefile
  self.pre_loaded_fixtures        = false

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  fixtures :all

  attr_accessor :request, :response, :controller

  # Add more helper methods to be used by all tests here...
  def logger
    ActiveRecord::Base.logger
  end

  # Ensures that the passed record is invalid by ActiveRecord standards.
  def assert_invalid(record)
    deny record.valid?, "#{record.inspect} should have been invalid"
  end

  def assert_model_saved(model, msg=nil)
    assert model.save, ["Could not save #{model.class}: [#{model.errors.full_messages.join(', ')}]", msg].compact.join("; ")
  end

  def assert_model_valid(model, msg=nil)
    assert model.valid?, ["Expected #{model.class} to be valid: [#{model.errors.full_messages.join(', ')}]", msg].compact.join("; ")
  end

  def assert_model_not_saved(model, msg=nil)
    assert !model.save, ["Expected not to be able to save #{model.class}", msg].compact.join("; ")
  end

  def assert_model_invalid(model, msg=nil)
    assert !model.valid?, ["Expected model #{model.class} to be invalid", msg].compact.join("; ")
  end
  alias_method :assert_model_not_valid, :assert_model_invalid

  def assert_blank(actual, message=nil)
    full_message = build_message(message, "<?> expected to be blank.\n", actual)
    assert_block(full_message) { actual.blank? }
  end

  def assert_include(expected, actual, message=nil)
    assert_respond_to actual, :include?, "#{actual.class.name} doesn't respond_to?(:include?)"
    msg = "#{actual.inspect} does not include #{expected.inspect}"
    msg << ": #{message}" unless message.blank?
    assert actual.include?(expected), msg
  end
  
  def assert_does_not_include(expected, actual, message=nil)
    assert_respond_to actual, :include?, "#{actual.class.name} doesn't respond_to?(:include?)"
    msg = "#{actual.inspect} includes #{expected.inspect}"
    msg << ": #{message}" unless message.blank?
    assert !actual.include?(expected), msg
  end
  alias_method :assert_not_include, :assert_does_not_include

  def assert_models_equal(expected_models, actual_models, message = nil)
    to_test_param = lambda { |r| "<#{r.class}:#{r.to_param}>" }
    full_message = build_message(message, "<?> expected but was\n<?>.\n",
      expected_models.collect(&to_test_param), actual_models.collect(&to_test_param))
    assert_block(full_message) { expected_models == actual_models }
  end

  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end

  def current_user=(user)
    if user then
      @account = user.account
      @request.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = user.id
    else
      @account = @request.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = nil
    end
  end

  def login!(party_or_symbol)
    party_or_symbol = parties(party_or_symbol) if Symbol === party_or_symbol
    raise ArgumentError, "Cannot login #{party_or_symbol.inspect}" unless party_or_symbol
    returning party_or_symbol do
      self.current_user = party_or_symbol
    end
  end

  def login_with_no_permissions!(party_or_symbol)
    returning login!(party_or_symbol) do |party|
      party.permission_grants.clear
      party.roles.clear
      party.update_effective_permissions
      party.save!
    end
  end

  def login_with_permissions!(party_or_symbol, *perms)
    returning login_with_no_permissions!(party_or_symbol) do |party|
      permissions = Permission.find(:all, :conditions => {:name => perms.map(&:to_s)})
      missing = perms.map(&:to_s) - permissions.map(&:name)
      missing.each do |name|
        permissions << Permission.create!(:name => name)
      end
      party.permissions = permissions
      party.update_effective_permissions
      party.save!
    end
  end

  def create_account(attrs={})
    returning(Account.new(attrs)) do |account|
      account.expires_at = 5.minutes.from_now
      account.save!
    end
  end

  alias_method :create_new_account, :create_account
  
  def new_session_path
    "/sessions/new"
  end
end

module Test::Unit::Assertions
  def deny(boolean, message = nil)
    message = build_message message, '<?> is not false or nil.', boolean
    assert_block message do
      not boolean
    end
  end
end

# Make sure we load all fixtures in integration tests too
class ActionController::IntegrationTest
  # Load all fixture data from the Rakefile
  self.pre_loaded_fixtures        = false

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  fixtures :all
end

module XlSuiteIntegrationHelpers
  # Calling #login without parameters logs the prototypical Bob in, without remembering his cookie.
  def login(email_address=parties(:bob).main_email.address, password="test", remember_me=false)
    get new_session_path
    assert_response :success
    assert_select "form[method=post][action$=?]", sessions_path, true, "Could not find login form (action=#{sessions_path}):\n#{response.body}" do
      assert_select "input[id=user_email]"
      assert_select "input[id=user_password][type=password]"
      assert_select "input[type=submit][value^=Login]"
    end

    post sessions_path, :user => {:email => email_address, :password => password}, :remember_me => remember_me ? "1" : "0"
    party = EmailContactRoute.find_by_address(email_address).routable
    assert_equal party.id, session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID],
        "Authenticated user not who we think he is: expected #{party.id}, found #{session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID]}"
  end

  def logout
    post "/sessions/destroy"
    assert_redirected_to new_session_url
    assert_nil session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID]
  end
end
