require "#{File.dirname(__FILE__)}/test_helper"

class RedirectTest < Test::Unit::TestCase
  CONTROLLER = "jamis_buck/routing/tricks"
  ACTION     = "do_redirect"

  # We need a special test request object, because the default assign_parameters
  # method tries to actually generate a URL from the parameters. That will fail
  # in these tests, because we're using a controller for which there is no route
  # (jamis_buck/routing/tricks).
  class SpecialTestRequest < ActionController::TestRequest
    def assign_parameters(controller_path, action, parameters)
      query_parameters[:controller] = controller_path
      query_parameters[:action] = action
      query_parameters.update(parameters)
    end
  end

  def setup
    ActionController::Routing::Routes.draw do |map|
      map.resources :jobs
      map.redirect  "/", :jobs
      map.redirect  "/job/:id", :job
    end
  end

  def test_without_redirect
    assert_recognition :get, "/jobs", :controller => "jobs", :action => "index"
    assert_recognition :get, "/jobs/5", :controller => "jobs", :action => "show", :id => "5"
  end

  def test_with_redirect
    assert_recognition :get, "/", :controller => CONTROLLER, :action => ACTION, :destination => :jobs
    assert_recognition :get, "/job/5", :controller => CONTROLLER, :action => ACTION, :destination => :job, :id => "5"
  end

  def test_do_redirect
    setup_tricks_controller!

    get :do_redirect, :destination => :jobs
    assert_redirected_to jobs_url

    get :do_redirect, :destination => :job, :id => 5
    assert_redirected_to job_url(5)
  end

  private

    def setup_tricks_controller!
      @controller = JamisBuck::Routing::TricksController.new
      @request = SpecialTestRequest.new
      @response = ActionController::TestResponse.new

      # prime the pump, so we can use named routes
      @controller.process(@request, @response)
    end

    # yes, I know about assert_recognizes, but it has proven problematic to
    # use in these tests, since it uses RouteSet#recognize (which actually
    # tries to instantiate the controller) and because it uses an awkward
    # parameter order.
    def assert_recognition(method, path, options)
      result = ActionController::Routing::Routes.recognize_path(path, :method => method)
      assert_equal options, result
    end

    # override the default build_request_uri method, so that we don't try to
    # generate a URL for tricks controller requests. In that case, we just
    # fake it, which is fine because the tricks controller doesn't care what
    # the original request URI was.
    def build_request_uri(action, parameters)
      if parameters[:destination]
        "/bogus/fakey/thing"
      else
        super
      end
    end
end
