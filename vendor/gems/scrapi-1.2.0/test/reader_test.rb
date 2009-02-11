# ScrAPI toolkit for Ruby
#
# Copyright (c) 2006 Assaf Arkin, under Creative Commons Attribution and/or MIT License
# Developed for http://co.mments.com
# Code and documention: http://labnotes.org


require "rubygems"
require "test/unit"
require "time" # rfc2822
require "webrick"
require "webrick/https"
require "logger"
require "stringio"
require File.join(File.dirname(__FILE__), "mock_net_http")
require File.join(File.dirname(__FILE__), "../lib", "scrapi")


class ReaderTest < Test::Unit::TestCase

  include Scraper


  WEBRICK_OPTIONS = {
    :BindAddredd=>"127.0.0.1",
    :Port=>2000,
    :Logger=>Logger.new(StringIO.new) # /dev/null
  }

  WEBRICK_TEST_URL = "http://127.0.0.1:2000/test.html"


  def setup
    Net::HTTP.reset_on_get
  end

  def teardown
    Net::HTTP.reset_on_get
  end


  #
  # Tests read_page.
  #

  def test_should_pass_path_and_user_agent
    # Test path, query string and user agent.
    Net::HTTP.on_get do |address, path, headers|
      assert_equal "localhost", address
      assert_equal "/path?query", path
      assert_equal "MyUserAgent", headers["User-Agent"]
      [Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK"), "nothing"]
    end
    response = Reader.read_page("http://localhost/path?query", :user_agent=>"MyUserAgent")
    assert_equal "http://localhost/path?query", response.url.to_s
    assert_equal "nothing", response.content
    assert_equal nil, response.last_modified
    assert_equal nil, response.etag
  end


  def test_should_handle_http_and_timeout_errors
    # Test timeout error and HTTP status that we can't process.
    Net::HTTP.on_get { |address, path, headers| raise TimeoutError }
    assert_raise(Reader::HTTPTimeoutError) do
      response = Reader.read_page("http://localhost/path?query")
    end
    Net::HTTP.on_get { |address, path, headers| [Net::HTTPRequestTimeOut.new(Net::HTTP.version_1_2, 408, "Timeout"),""] }
    assert_raise(Reader::HTTPTimeoutError) do
      response = Reader.read_page("http://localhost/path?query")
    end
  end


  def test_should_fail_on_too_many_redirects
    # Test too many redirections.
    Net::HTTP.on_get do |address, path, headers|
      response = Net::HTTPMovedPermanently.new(Net::HTTP.version_1_2, 301, "Moved")
      response["location"] = "http://localhost"
      [response, ""]
    end
    assert_raise(Reader::HTTPRedirectLimitError) do
      response = Reader.read_page("http://localhost/path?query")
    end
    Net::HTTP.on_get do |address, path, headers|
      response = Net::HTTPRedirection.new(Net::HTTP.version_1_2, 300, "Moved")
      response["location"] = "http://localhost"
      [response, ""]
    end
    assert_raise(Reader::HTTPRedirectLimitError) do
      response = Reader.read_page("http://localhost/path?query")
    end
  end


  def test_should_validate_redirect_url
    # Test validation of redirection URI.
    Net::HTTP.on_get do |address, path, headers|
      response = Net::HTTPRedirection.new(Net::HTTP.version_1_2, 300, "Moved")
      response["location"] = "ftp://notsupported"
      [response, ""]
    end
    assert_raise(Reader::HTTPInvalidURLError) do
      response = Reader.read_page("http://localhost/path?query")
    end
  end


  def test_should_support_redirection
    # Test working redirection. Redirect only once and test response URL.
    # Should be new URL for permanent redirect, same URL for all other redirects.
    Net::HTTP.on_get do |address, path, headers|
      if path.empty?
        [Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK"), ""]
      else
        response = Net::HTTPRedirection.new(Net::HTTP.version_1_2, 300, "Moved")
        response["Location"] = "http://localhost"
        [response, ""]
      end
    end
    assert_nothing_raised() do
      response = Reader.read_page("http://localhost/path?query")
      assert_equal "http://localhost/path?query", response.url.to_s
    end
  end


  def test_should_support_permanent_redirection
    # Test working redirection. Redirect only once and test response URL.
    # Should be new URL for permanent redirect, same URL for all other redirects.
    Net::HTTP.on_get do |address, path, headers|
      if path == "/"
        [Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK"), ""]
      else
        response = Net::HTTPMovedPermanently.new(Net::HTTP.version_1_2, 301, "Moved")
        response["location"] = "http://localhost/"
        [response, ""]
      end
    end
    assert_nothing_raised() do
      response = Reader.read_page("http://localhost/path?query")
      assert_equal "http://localhost/", response.url.to_s
    end
  end


  def test_should_use_cache_control
    # Test Last Modified and ETag headers. First, that they are correctly
    # returned from headers to response object. Next, that passing right
    # headers in options returns nil body and same values (no change),
    # passing wrong/no headers, returnspage.
    time = Time.new.rfc2822
    Net::HTTP.on_get do |address, path, headers|
      response = Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK")
      response["Last-Modified"] = time
      response["ETag"] = "etag"
        [response, "nothing"]
    end
    response = Reader.read_page("http://localhost/path?query")
    assert_equal time, response.last_modified
    assert_equal "etag", response.etag
    Net::HTTP.on_get do |address, path, headers|
      if headers["Last-Modified"] == time and headers["ETag"] == "etag"
        [Net::HTTPNotModified.new(Net::HTTP.version_1_2, 304, "Same"), ""]
      else
        [Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK"), "nothing"]
      end
    end
    response = Reader.read_page("http://localhost/path?query")
    assert_equal "nothing", response.content
    response = Reader.read_page("http://localhost/path?query", :last_modified=>time, :etag=>"etag")
    assert_equal nil, response.content
    assert_equal time, response.last_modified
    assert_equal "etag", response.etag
  end


  def test_should_find_encoding
    # Test working redirection. Redirect only once and test response URL.
    # Should be new URL for permanent redirect, same URL for all other redirects.
    Net::HTTP.on_get do |address, path, headers|
      response = Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK")
      response["content-type"] = "text/html; charset=bogus"
      [response, ""]
    end
    response = Reader.read_page("http://localhost/path?query")
    assert_equal "bogus", response.encoding
  end


  #
  # Tests parse_page.
  #

  def test_should_parse_html_page
    html = Reader.parse_page("<html><head></head><body><p>something</p></body></html>").document
    assert_equal 1, html.find_all(:tag=>"head").size
    assert_equal 1, html.find_all(:tag=>"body").size
    assert_equal 1, html.find(:tag=>"body").find_all(:tag=>"p").size
    assert_equal "something", html.find(:tag=>"body").find(:tag=>"p").children.join
  end


  def test_should_use_tidy_if_specified
    # This will only work with Tidy which adds the head/body parts,
    # HTMLParser doesn't fix the HTML.
    html = Reader.parse_page("<p>something</p>", nil, {}).document
    assert_equal 1, html.find_all(:tag=>"head").size
    assert_equal 1, html.find_all(:tag=>"body").size
    assert_equal 1, html.find(:tag=>"body").find_all(:tag=>"p").size
    assert_equal "something", html.find(:tag=>"body").find(:tag=>"p").children.join
  end


  #
  # Other tests.
  #

  def test_should_handle_encoding_correctly
    # Test content encoding returned from HTTP server.
    with_webrick do |server, params|
      server.mount_proc "/test.html" do |req,resp|
        resp["Content-Type"] = "text/html; charset=my-encoding"
        resp.body = "Content comes here"
      end
      page = Reader.read_page(WEBRICK_TEST_URL)
      page = Reader.parse_page(page.content, page.encoding)
      assert_equal "my-encoding", page.encoding
    end
    # Test content encoding in HTML http-equiv header
    # that overrides content encoding returned in HTTP.
    with_webrick do |server, params|
      server.mount_proc "/test.html" do |req,resp|
        resp["Content-Type"] = "text/html; charset=my-encoding"
        resp.body = %Q{
<html>
<head>
<meta http-equiv="content-type" value="text/html; charset=other-encoding">
</head>
<body></body>
</html>
        }
      end
      page = Reader.read_page(WEBRICK_TEST_URL)
      page = Reader.parse_page(page.content, page.encoding)
      assert_equal "other-encoding", page.encoding
    end
  end

  def test_should_support_https
    begin
      options = WEBRICK_OPTIONS.dup.update(
        :SSLEnable=>true,
        :SSLVerifyClient => ::OpenSSL::SSL::VERIFY_NONE,
        :SSLCertName => [ ["C","JP"], ["O","WEBrick.Org"], ["CN", "WWW"] ]
      )
      server = WEBrick::HTTPServer.new(options)
      trap("INT") { server.shutdown }
      Thread.new { server.start }
      server.mount_proc "/test.html" do |req,resp|
        resp.body = %Q{
<html>
<head>
<title>test https</title>
</head>
<body></body>
</html>
      }
      end
      # Make sure page not HTTP accessible.
      assert_raises(Reader::HTTPUnspecifiedError) do
        Reader.read_page(WEBRICK_TEST_URL)
      end
      page = Reader.read_page(WEBRICK_TEST_URL.gsub("http", "https"))
      page = Reader.parse_page(page.content, page.encoding)
      assert_equal "<title>test https</title>",
         page.document.find(:tag=>"title").to_s
      server.shutdown
    ensure
      server.shutdown if server
    end
  end


private

  def with_webrick(params = nil)
    begin
      server = WEBrick::HTTPServer.new(WEBRICK_OPTIONS)
      trap("INT") { server.shutdown }
      Thread.new { server.start }
      yield server, params
      server.shutdown
    ensure
      server.shutdown if server
    end
  end

end
