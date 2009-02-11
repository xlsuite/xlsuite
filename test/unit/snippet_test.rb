require File.dirname(__FILE__) + "/../test_helper"

class SnippetTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @snippet = @account.snippets.create!(:title => "home", :body => "home snippet", :creator => @account.owner)
  end

  context "A snippet with '**' as domain pattern on the 'xlsuite.com' domain" do
    setup do
      @snippet.update_attributes(:domain_patterns => "**")
      @domain = Domain.new(:name => "xlsuite.com")
      @domain.save(false)
    end

    should "be reachable" do
      assert_equal @snippet, @account.snippets.find_by_domain_and_title(@domain, "home")
    end

    context "and a second snippet with 'xlsuite.com' domain pattern" do
      setup do
        @snippet1 = @account.snippets.create!(:title => "home", :domain_patterns => "xlsuite.com", :creator => @account.owner)
      end

      should "prefer the more specific pattern when visiting the xlsuite.com" do
        assert_equal @snippet1, @account.snippets.find_by_domain_and_title(@domain, "home")
      end
    end
  end
  
  context "A new snippet containing that refer to itself" do
    setup do
      @snippet.body = %Q`aloha this is a test {% render_snippet title:"home" %}`
    end
    
    should "not be saveable by default" do
      assert_equal false, @snippet.save
    end
    
    should "be saveable after ignore_warnings is set" do
      @snippet.ignore_warnings = true
      assert_equal true, @snippet.save
    end
  end
end
