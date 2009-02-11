require File.dirname(__FILE__) + '/../test_helper'

class LinkNoTitleTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @link = @account.links.create(:url => 'http://test.host')
  end

  def test_valid_account
    assert_equal @account, @link.account
  end
  
  def test_not_valid_when_no_title
    assert !@link.valid?, 'Link should not be valid -- missing title'
  end

  def test_url_left_alone
    assert_equal 'http://test.host', @link.url
  end
end

class LinkNoUrlTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @link = @account.links.create(:title => 'Some bloke')
  end

  def test_not_valid_when_no_url
    assert !@link.valid?, 'Link should not be valid -- missing url'
  end
end

class LinkInvalidUrlTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @link = @account.links.create(:title => 'Blokie', :url => 'city.vancouver.bc.ca')
  end

  def test_valid_with_title_and_url
    assert_valid @link
  end

  def test_reformats_url_to_
    @link.valid?
    assert_equal 'http://city.vancouver.bc.ca', @link.url
  end
end
