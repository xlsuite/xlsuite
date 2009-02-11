require File.dirname(__FILE__) + '/../../test_helper'

module XlSuite
  class RenderSnippetTest < Test::Unit::TestCase
    context "A liquid template containing render_snippet that refer to itself" do
      setup do
        @account = Account.find(:first)
        @snippet = @account.snippets.create!(:title => "recursion", :body => %Q`XLsuite {% render_snippet title:'recursion' %}`, :creator => parties(:bob))
      end

      should "not recur indefinitely" do
        assigns = {}
        registers = {"account" => @account.reload, "domain" => Domain.find(:first)}
        context = ::Liquid::Context.new(assigns, registers, false)

        out = ::Liquid::Template.parse(%Q`{% render_snippet title:'recursion' %}`).render!(context)
        assert_equal (["XLsuite"]*10).join(" ") + " ", out
      end
    end
  end
end
