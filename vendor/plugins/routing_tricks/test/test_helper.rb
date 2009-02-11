require 'test/unit'

PLUGIN_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
VENDOR_ROOT = File.expand_path(File.join(PLUGIN_ROOT, "..", ".."))

%w(actionpack activesupport railties).each do |framework|
  path = File.expand_path(File.join(VENDOR_ROOT, "rails", framework, "lib"))
  $LOAD_PATH.unshift path
end

require 'active_support'
require 'action_controller'
require 'action_controller/test_process'

$LOAD_PATH.unshift "#{PLUGIN_ROOT}/lib"
require "#{PLUGIN_ROOT}/init"

class ApplicationController < ActionController::Base
end

class PublicController < ApplicationController
end

class AdminController < ApplicationController
end

class SignupController < ApplicationController
end

class BlogController < ApplicationController
end

class Test::Unit::TestCase
  private
    # yes, I know about assert_recognizes, but it has proven problematic to
    # use in these tests, since it uses RouteSet#recognize (which actually
    # tries to instantiate the controller) and because it uses an awkward
    # parameter order.
    def assert_recognition(method, path, options)
      result = ActionController::Routing::Routes.recognize_path(path, :method => method)
      assert_equal options, result
    end

    def assert_recognizes_from_request(request, options)
      controller = ActionController::Routing::Routes.recognize(request)
      assert_equal options, request.symbolized_path_parameters
    end

    def new_request(url=nil)
      request = ActionController::TestRequest.new

      if url
        uri = URI.parse(url)
        request.env["HTTPS"] = uri.scheme == "https" ? "on" : nil
        request.host = uri.host
        request.request_uri = uri.path.empty? ? "/" : uri.path
      end

      request
    end
end