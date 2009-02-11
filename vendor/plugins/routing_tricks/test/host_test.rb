require "#{File.dirname(__FILE__)}/test_helper"

class HostTest < Test::Unit::TestCase
  def setup
    ActionController::Routing::Routes.draw do |map|
      map.connect "/", :controller => "admin", :action => "index", :conditions => { :subdomain => "admin" }
      map.connect "/", :controller => "public", :action => "index"

      map.connect "/signup", :controller => "signup", :action => "index", :conditions => { :domain => "marketing.test" }

      map.connect "/blog", :controller => "blog", :action => "index", :conditions => { :host => "blog.marketing.test" }

      map.connect ":command", :controller => "public", :action => "catchall"
    end
  end

  def test_route_with_subdomain
    request = new_request "http://www.happystuff.test"
    assert_recognizes_from_request request, :controller => "public", :action => "index"

    request = new_request "http://admin.happystuff.test"
    assert_recognizes_from_request request, :controller => "admin", :action => "index"
  end

  def test_route_with_domain
    request = new_request "http://www.happystuff.test/signup"
    assert_recognizes_from_request request, :controller => "public", :action => "catchall", :command => "signup"

    request = new_request "http://www.marketing.test/signup"
    assert_recognizes_from_request request, :controller => "signup", :action => "index"
  end

  def test_route_with_host
    request = new_request "http://www.happystuff.test/blog"
    assert_recognizes_from_request request, :controller => "public", :action => "catchall", :command => "blog"

    request = new_request "http://www.marketing.test/blog"
    assert_recognizes_from_request request, :controller => "public", :action => "catchall", :command => "blog"

    request = new_request "http://blog.marketing.test/blog"
    assert_recognizes_from_request request, :controller => "blog", :action => "index"
  end
end
