require File.dirname(__FILE__) + "/../test_helper"

class CacheControlTest < Test::Unit::TestCase
  include CacheControl
  attr_accessor :cache_timeout_in_seconds, :cache_control_directive, :updated_at

  context "A cache_timeout_in_seconds of 0" do
    setup do
      @cache_timeout_in_seconds = 0
    end

    context "and cache_control_directive of 'private'" do
      setup do
        @cache_control_directive = "private"
      end

      should "set Cache-Control: max-age=0" do
        assert_include "max-age=0", cache_control_headers["Cache-Control"]
      end

      should "set Cache-Control: private" do
        assert_include "private", cache_control_headers["Cache-Control"]
      end

      should "set Pragma: no-cache" do
        assert_include "no-cache", cache_control_headers["Pragma"]
      end

      should "NOT set the Last-Modified header" do
        assert_not_include "Last-Modified", cache_control_headers
      end

      should "set Expires: <now>" do
        assert_equal Time.now.to_s(:http), cache_control_headers["Expires"]
      end
    end
  end

  context "A cache_control_directive of 'public'" do
    setup do
      @cache_control_directive = "public"
    end

    should "NOT set the Last-Modified header" do
      assert_not_include "Last-Modified", cache_control_headers
    end

    should "set Cache-Control: public" do
      assert_include "public", cache_control_headers["Cache-Control"]
    end
  end

  context "A cache_control_directive of 'private'" do
    setup do
      @cache_control_directive = "private"
    end

    should "NOT set the Last-Modified header" do
      assert_not_include "Last-Modified", cache_control_headers
    end

    should "set Cache-Control: private" do
      assert_include "private", cache_control_headers["Cache-Control"]
    end
  end

  context "A cache_control_directive of 'no-cache'" do
    setup do
      @cache_control_directive = "no-cache"
    end

    should "NOT set the Last-Modified header" do
      assert_not_include "Last-Modified", cache_control_headers
    end

    should "NOT set Expires" do
      assert_not_include "Expires", cache_control_headers.keys
    end

    should "set Cache-Control: no-cache" do
      assert_include "no-cache", cache_control_headers["Cache-Control"]
    end

    should "include Pragma header and set to no-cache" do
      assert_include "Pragma", cache_control_headers.keys
      assert_equal "no-cache", cache_control_headers["Pragma"]
    end

    context "with cache timeout seconds set" do
      setup do
        @cache_timeout_in_seconds = 300
      end

      should "NOT set the Last-Modified header" do
        assert_not_include "Last-Modified", cache_control_headers
      end

      should "NOT set Expires" do
        assert_not_include "Expires", cache_control_headers.keys
      end

      should "set Cache-Control: no-cache" do
        assert_include "no-cache", cache_control_headers["Cache-Control"]
      end

      should "include Pragma header and set to no-cache" do
        assert_include "Pragma", cache_control_headers.keys
        assert_equal "no-cache", cache_control_headers["Pragma"]
      end

      should "NOT set Cache-Control: max-age" do
        assert_not_include "max-age", cache_control_headers["Cache-Control"]
      end
    end
  end

  context "An object with values in updated_at(3.hours.ago), cache_timeout_in_seconds(2.hours) and cache_control_directive(public)" do
    setup do
      @cache_timeout_in_seconds = 2.hours
      @cache_control_directive = "public"
      @updated_at = 3.hours.ago
    end

    should "NOT set the Last-Modified header" do
      assert_not_include "Last-Modified", cache_control_headers
    end

    should "not set the Pragma header" do
      assert_not_include "Pragma", cache_control_headers.keys
    end

    should "set Expires: <2 hours>" do
      assert_equal 2.hours.from_now.to_s(:http), cache_control_headers["Expires"]
    end

    should "set Cache-Control: public;max-age=<2 hours>" do
      assert_equal "public;max-age=#{2.hours}", cache_control_headers["Cache-Control"]
    end

    should "not set any other headers" do
      headers = cache_control_headers
      headers.delete("Pragma")
      headers.delete("Cache-Control")
      headers.delete("Expires")
      assert headers.empty?, headers.inspect
    end
  end

  context "An object with nil in updated, cache_timeout_in_seconds and cache_control_directive" do
    should "not set any headers" do
      headers = cache_control_headers
      assert headers.empty?, headers.inspect
    end
  end
end
