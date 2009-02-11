require File.dirname(__FILE__) + '/../test_helper'
require 'application_helper'

class ApplicationHelperTest < Test::Unit::TestCase
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  def test_format_nil_money
    assert_equal nil.to_s, format_money(nil, 'NIL')
  end

  def test_format_non_money
    assert_equal 141.to_s, format_money(141, 'NIL')
  end

  def test_format_empty_money
    assert_equal 'NIL', format_money(Money.empty, 'NIL')
  end

  def test_format_real_money
    assert_equal '29.47', format_money(Money.new(2947))
  end
end

class TestController < ApplicationController
  skip_before_filter :login_required

  def truncate
    render :inline => "<%= truncate(params[:text], (params[:length] || 20).to_i) %>",
        :content_type => 'text/plain', :layout => false
  end
end

class ApplicationHelperTruncationTest < Test::Unit::TestCase
  def setup
    @controller = TestController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_truncation_without_dangling_entity_ref
    get :truncate, :length => 12.to_s,
        :text => 'the words &apos;time for all good men&apos;'
    assert_equal 'the words...', @response.body
  end

  def test_truncation_with_final_ampersand
    get :truncate, :length => 14.to_s,
        :text => 'the words &apos;time for all good men&apos;'
    assert_equal 'the words...', @response.body
  end

  def test_truncation_with_dangling_entity_ref
    get :truncate, :length => 15.to_s,
        :text => 'the words &apos;time for all good men&apos;'
    assert_equal 'the words...', @response.body
  end

  def test_truncation_with_dangling_value_ref
    get :truncate, :length => 15.to_s,
        :text => 'the words &#657;time for all good men&#657;'
    assert_equal 'the words...', @response.body
  end

  def test_truncation_with_dangling_hex_ref
    get :truncate, :length => 15.to_s,
        :text => 'the words &x9d8;time for all good men&x9d8;'
    assert_equal 'the words...', @response.body
  end

  def test_truncation_allows_entity_at_end
    get :truncate, :length => 19.to_s,
        :text => 'the words &x9d8;time for all good men&x9d8;'
    assert_equal 'the words &x9d8;...', @response.body
  end
end
