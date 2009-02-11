require File.dirname(__FILE__) + '/../test_helper'

class LayoutTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @layout = @account.layouts.create!(:title => "HTML", :domain_patterns => "**", :author => @account.owner)

    Domain.any_instance.stubs(:rebuild_routes)
    Domain.any_instance.stubs(:rebuild_routes!)

    @parser = mock("parser")
    Liquid::Template.stubs(:parse).returns(@parser)
  end

  context "A new layout" do
    setup do
      @layout = Layout.new(:content_type => nil)
      @layout.valid?
    end

    should "be invalid unless it has an account" do
      assert_include "Account can't be blank", @layout.errors.full_messages
      @layout.account = @account
      @layout.valid?
      assert_not_include "Account can't be blank", @layout.errors.full_messages
    end

    should "be invalid unless it has a content type" do
      assert_include "Content type can't be blank", @layout.errors.full_messages
      @layout.content_type = "text/html"
      @layout.valid?
      assert_not_include "Content type can't be blank", @layout.errors.full_messages
    end

    should "be invalid unless it has a encoding" do
      assert_include "Title can't be blank", @layout.errors.full_messages
      @layout.encoding = "UTF-8"
      @layout.valid?
      assert_not_include "Encoding can't be blank", @layout.errors.full_messages
    end

    should "be invalid unless it has a title" do
      assert_include "Title can't be blank", @layout.errors.full_messages
      @layout.title = "layout title"
      @layout.valid?
      assert_not_include "Title can't be blank", @layout.errors.full_messages
    end

    should "be invalid unless there is an author" do
      assert_include "Author can't be blank", @layout.errors.full_messages
      @layout.author = @account.owner
      @layout.valid?
      assert_not_include "Author can't be blank", @layout.errors.full_messages
    end
  end

  context "A layout with '**' as domain pattern on the 'xlsuite.com' domain" do
    setup do
      @domain = Domain.new(:name => "xlsuite.com")
      @domain.save(false)
    end

    should "be reachable" do
      assert_equal @layout, @account.layouts.find_by_domain_and_title(@domain, "HTML")
    end

    context "and a second layout with 'xlsuite.com' domain pattern" do
      setup do
        @layout1 = @account.layouts.create!(:title => "HTML", :domain_patterns => "xlsuite.com", :author => @account.owner)
      end

      should "prefer the more specific pattern when visiting the xlsuite.com" do
        assert_equal @layout1, @account.layouts.find_by_domain_and_title(@domain, "HTML")
      end
    end
    
    should "delegate rendering to Liquid::Template" do
      @page = mock("page")
      @layout.expects(:parsed_template).returns(@parser)
      @parser.expects(:render!).with() {|context, registers|
        context["page"] && context["page"].kind_of?(PageDrop)
      }.returns(:the_page)
      assert_equal :the_page, @layout.render({"page" => PageDrop.new(@page)})[:text]
    end
  end

  context "An existing valid layout and a page that uses the layout" do
    setup do
      @parser.stubs(:render!).returns("")
      @layout = @account.layouts.create!(:title => "HTML", :body => "{{ page.body }}", :author => @account.owner)

      @page = @account.pages.create!(:layout => "HTML", :title => "Home", :behavior => "plain_text",
                                     :behavior_values => {:text => "page text"}, :creator => @account.owner)
    end

    should "rename pages that use the layout if :rename_pages is true" do
      @layout.update_attributes(:rename_pages => true, :title => "XHTML")
      assert_equal "XHTML", @page.reload.layout, "Page should have changed layout"
    end

    should "not rename pages that use the layout if :rename_pages is not true" do
      @layout.update_attributes(:rename_pages => nil, :title => "XHTML")
      assert_equal "HTML", @page.reload.layout, "Page should NOT have changed layout"
    end
  end
end
