require File.dirname(__FILE__) + '/../test_helper'

class PageTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @domain = @account.domains.first
    Domain.any_instance.stubs(:rebuild_routes)
    Domain.any_instance.stubs(:rebuild_routes!)
  end

  context "A published page with 'xlsuite.com' as domain pattern" do
    setup do
      @page = @account.pages.create!(:title => "Home Page", :behavior => "plain_text",
                                     :fullslug => "", :domain_patterns => "xlsuite.com",
                                     :behavior_values => {:text => "-- home page text --"},
                                     :status => "published", :creator => parties(:bob),
                                     :layout => "HTML")
      @domain = Domain.new
    end

    context "on the 'xlsuite.com' domain" do
      setup do
        @domain.name = "xlsuite.com"
      end
      should "match a Domain with name 'xlsuite.com'" do
        assert @page.matches_domain?(@domain)
      end

      should "be found when searching for all roots the 'xlsuite.com' domain" do
        assert_include @page, @account.pages.find_all_in_domain(@domain)
      end
    end

    context "on the 'xltester.com' domain" do
      setup do
        @domain.name = "xltester.com"
      end

      should "not match a Domain with name 'xltester.com'" do
        deny @page.matches_domain?(@domain)
      end

      should "not be found when searching for all roots the 'xltester.com' domain" do
        assert_not_include @page, @account.pages.find_all_in_domain(@domain)
      end
    end
    
    context "on the 'subdomain.xlsuite.com' domain" do
      setup do
        @domain.name = "subdomain.xlsuite.com"
      end
      
      should "not match a Domain with name 'subdomain.xlsuite.com'" do
        deny @page.matches_domain?(@domain)
      end

      should "not be found when searching for all roots the 'subdomain.xlsuite.com' domain" do
        assert_not_include @page, @account.pages.find_all_in_domain(@domain)
      end
    end
  end
  
  context "A published page with '*.xlsuite.com' as domain pattern" do
    setup do
      @page = @account.pages.create!(:title => "Home Page", :behavior => "plain_text",
                                     :fullslug => "", :domain_patterns => "*.xlsuite.com",
                                     :behavior_values => {:text => "-- home page text --"},
                                     :status => "published", :creator => parties(:bob),
                                     :layout => "HTML")
      @domain = Domain.new
    end

    context "on the 'xlsuite.com' domain" do
      setup do
        @domain.name = "xlsuite.com"
      end
      should "not match a Domain with name 'xlsuite.com'" do
        deny @page.matches_domain?(@domain)
      end

      should "not be found when searching for all roots the 'xlsuite.com' domain" do
        assert_not_include @page, @account.pages.find_all_in_domain(@domain)
      end
    end
    
    context "on the 'subdomain.xlsuite.com' domain" do
      setup do
        @domain.name = "subdomain.xlsuite.com"
      end
      should "match a Domain with name 'subdomain.xlsuite.com'" do
        assert @page.matches_domain?(@domain)
      end

      should "be found when searching for all roots the 'xlsuite.com' domain" do
        assert_include @page, @account.pages.find_all_in_domain(@domain)
      end
    end
  end

  context "A published page with '**' as domain pattern on the 'xlsuite.com' domain" do
    setup do
      @page = @account.pages.create!(:title => "Home Page", :behavior => "plain_text",
                                     :fullslug => "", :domain_patterns => "**",
                                     :behavior_values => {:text => "-- home page text --"},
                                     :status => "published", :creator => parties(:bob),
                                     :layout => "HTML")
      @domain = Domain.new(:name => "xlsuite.com")
      @domain.save(false)
    end
  end

  context "A new page" do
    setup do
      @page = Page.new
      deny @page.valid?
    end

    should "have a depth of 0 when the fullslug is ''" do
      assert_equal 0, @page.depth
    end

    should "have a depth of 1 when the fullslug is 'products'" do
      @page.fullslug = "products"
      assert_equal 1, @page.depth
    end

    should "have a depth of 2 when the fullslug id 'products/lights'" do
      @page.fullslug = "products/lights"
      assert_equal 2, @page.depth
    end

    should "be invalid unless there is a layout" do
      assert_include "Layout can't be blank", @page.errors.full_messages
      @page.layout = "HTML"
      @page.valid?
      assert_not_include "layout can't be blank", @page.errors.full_messages
    end

    should "be invalid unless there is an account" do
      assert_include "Account can't be blank", @page.errors.full_messages
      @page.account = @account
      @page.valid?
      assert_not_include "Account can't be blank", @page.errors.full_messages
    end

    should "be invalid unless there is a title" do
      assert_include "Title can't be blank", @page.errors.full_messages
      @page.title = "page title"
      @page.valid?
      assert_not_include "Title can't be blank", @page.errors.full_messages
    end

    should "be valid with a fullslug of '/products'" do
      @page.fullslug = "/products"
      @page.valid?
      assert_not_include "Fullslug must NOT begin with a slash (/) and can contain only letters, numbers, colons (:), dashes (-), underscores (_), dots (.) or percent signs (%)", @page.errors.full_messages
    end

    should "be valid with a fullslug of '/'" do
      @page.fullslug = "/"
      @page.valid?
      assert_not_include "Fullslug must NOT begin with a slash (/) and can contain only letters, numbers, colons (:), dashes (-), underscores (_), dots (.) or percent signs (%)", @page.errors.full_messages
    end
  end

  context "A saved and published page" do
    setup do
      @layout = @account.layouts.create!(:title => "HTML", :author => @account.owner, :body => "{{ page.body }}")
      @page = @account.pages.create!(:title => "Home Page", :creator => @account.owner, :fullslug => "",
                                     :status => "published", :layout => "HTML", :behavior => "plain_text")
      @products = @account.pages.create!(:title => "Products", :creator => @page.creator, :fullslug => "products",
                                         :account => @account, :status => "published", :layout => "HTML")
      @lights = @account.pages.create!(:title => "Lights", :creator => @page.creator, :fullslug => "products/lights",
                                           :account => @account, :status => "published", :layout => "HTML")
    end

    context "referencing a missing layout" do
      setup do
        @page.layout = "XHTML"
        @page.save!
      end

      should "generate a default layout" do
        options = @page.render_on_domain(@domain)
        assert_equal "text/html; charset=UTF-8", options[:content_type]
      end
    end

    should "copy it's fullslug, layout and domain patterns when #copy is called" do
      @lights.update_attribute(:layout, "HTML")
      @copy = @lights.copy
      assert_equal @copy.fullslug, @lights.fullslug
      assert_equal @copy.domain_patterns, @lights.domain_patterns
      assert_equal @copy.layout, @lights.layout
    end

    should "calculate the whole fullslug for the bottom-most page" do
      assert_equal "products/lights", @lights.fullslug
    end

    should "update the fullslug when an intermediate page changes slug" do
      @products.update_attributes(:fullslug => "my-products")
      assert_equal "my-products/lights", @lights.reload.fullslug
    end

    should "delegate rendering of itself to it's layout" do
      @layout.update_attributes(:body => "whatever")
      assert_equal "whatever", @page.render_on_domain(@domain)[:text]
    end

    should "delegate rendering the editor to it's behavior" do
      PlainTextBehavior.any_instance.expects(:render_edit).returns(:whatever)
      assert_equal :whatever, @page.render_edit
    end

    should "serialize behavior values on save" do
      PlainTextBehavior.any_instance.expects(:serialize).with(:text => "abc")
      assert(@page.update_attributes(:behavior_values => {:text => "abc"}))
    end

    should "deserialize behavior values on access" do
      PlainTextBehavior.any_instance.expects(:deserialize).returns(:original_values)
      assert_equal :original_values, @page.behavior_values
    end

    should "find the layout instance by domain and title" do
      Layout.expects(:find_by_domain_and_title).with(@domain, "HTML").returns(layout = mock("layout"))
      assert_equal layout, @page.find_layout(@domain)
    end
  end

  context "Creating a page" do
    context "outside a #disable_domain_routing_update block" do
      setup do
        accounts(:wpul).pages.create!(:title => "this is a test", :layout => "HTML", :domain_patterns => "**", :status => "published")
      end

      should_change "MethodCallbackFuture.count", :by => 1
    end

    context "within a #disable_domain_routing_update block" do
      setup do
        Page.disable_domain_routing_update do
          accounts(:wpul).pages.create!(:title => "this is a test", :layout => "HTML", :domain_patterns => "**", :status => "published")
        end
      end

      should_not_change "MethodCallbackFuture.count"
    end
  end
end
