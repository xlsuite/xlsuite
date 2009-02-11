require File.dirname(__FILE__) + '/../test_helper'
require 'email_accounts_controller'

# Re-raise errors caught by the controller.
class EmailAccountsController; def rescue_action(e) raise e end; end

class EmailAccountsControllerTest < Test::Unit::TestCase
  def setup
    @controller = EmailAccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
