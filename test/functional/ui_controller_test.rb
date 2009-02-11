require File.dirname(__FILE__) + '/../test_helper'
require 'ui_controller'

# Re-raise errors caught by the controller.
class UiController; def rescue_action(e) raise e end; end

class UiControllerTest < Test::Unit::TestCase
  def setup
    @controller = UiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_connect_to_parties_index_ui
    get :connect, :path => %w(parties)
    assert_response :success
    assert_template "parties/index_ui"
    assert_match %r{^text/javascript}, @response.headers["Content-Type"]
  end

  def test_connect_to_pages_index_ui
    get :connect, :path => %w(pages)
    assert_response :success
    assert_template "pages/index_ui"
    assert_match %r{^text/javascript}, @response.headers["Content-Type"]
  end

  def test_connect_to_parties_general_ui
    get :connect, :path => %w(parties general)
    assert_response :success
    assert_template "parties/general_ui"
    assert_match %r{^text/javascript}, @response.headers["Content-Type"]
  end
end
