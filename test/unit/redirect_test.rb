require File.dirname(__FILE__) + "/../test_helper"

class RedirectTest < Test::Unit::TestCase
  def setup
    @account = accounts(:wpul)
  end

  should "be valid with a fullslug of '/index.html'" do
    redirect = @account.redirects.build(:fullslug => "/index.html", :target => "/", :creator => parties(:bob), :status => "published")
    valid = redirect.valid?
    assert valid, redirect.errors.full_messages
  end

  should "be valid with parens" do
    fullslug = URI.parse("http://lesliefield.com/images/miss_thriftway_(1)_colour.jpg").path
    redirect = @account.redirects.build(:fullslug => fullslug, :target => "/", :creator => parties(:bob), :status => "published")
    valid = redirect.valid?
    assert valid, "Fullslug: #{fullslug.inspect} has errors: #{redirect.errors.full_messages.to_sentence}"
  end

  should "be invalid with a redirect of '/' to '/'" do
    redirect = create_redirect(:fullslug => "/", :target => "/")
    deny redirect.valid?, "Redirect should have been invalid: #{redirect.errors.full_messages}"
  end

  should "be invalid with a redirect of 'a' to '/a'" do
    redirect = create_redirect(:fullslug => "a", :target => "/a")
    deny redirect.valid?, "Redirect should have been invalid: #{redirect.errors.full_messages}"
  end
  
  should "be invalid with a redirect of '/a' to '/a'" do
    redirect = create_redirect(:fullslug => "/a", :target => "/a")
    deny redirect.valid?, "Redirect should have been invalid: #{redirect.errors.full_messages}"
  end

  should "be valid with a redirect of '/a' to 'a'" do
    redirect = create_redirect(:fullslug => "/a", :target => "a")
    assert redirect.valid?, "Redirect should have been valid #{redirect.errors.full_messages}"
  end

  should "be valid with a redirect of '/a/' to 'a'" do
    redirect = create_redirect(:fullslug => "/a/", :target => "a")
    assert redirect.valid?, "Redirect should have been valid #{redirect.errors.full_messages}"
  end

  should "be valid with a redirect of '/a' to 'b'" do
    redirect = create_redirect(:fullslug => "/a", :target => "/b")
    assert redirect.valid?, "Redirect should have been valid: #{redirect.errors.full_messages}"
  end
end
