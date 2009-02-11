require File.dirname(__FILE__) + '/../test_helper'

class LinkContactRouteValidationTest < Test::Unit::TestCase
  def setup
    @route = LinkContactRoute.new
  end

  def test_valid_if_http_protocol
    @route.url = "http://a.company.com/"
    @route.valid?
    assert_nil @route.errors.on(:url)
  end

  def test_valid_if_ftp_protocol
    @route.url = "ftp://a.company.com/"
    @route.valid?
    assert_nil @route.errors.on(:url)
  end

  def test_valid_if_https_protocol
    @route.url = "https://a.company.com/"
    @route.valid?
    assert_nil @route.errors.on(:url)
  end

  def test_invalid_if_missing_url
    @route.url = nil
    @route.valid?
    assert_match /can't be blank/, @route.errors.on(:url).to_s
  end

  def test_http_protocol_prepended_when_reading_formatted_url
    @route.url = "a.company.com"
    assert_equal "http://a.company.com", @route.formatted_url
  end
end
