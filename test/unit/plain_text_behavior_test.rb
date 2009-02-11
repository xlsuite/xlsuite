require File.dirname(__FILE__) + '/../test_helper'

class PlainTextBehaviorTest < Test::Unit::TestCase
  def setup
    @page = stub_everything("page")
    @template = mock("template")
    @behavior = PlainTextBehavior.new(@page, @template)
  end

  def test_serialize_stores_text_in_body
    @page.expects(:body=).with("this is a test\n<br/>Bla")
    @behavior.serialize(:text => "this is a test\n<br/>Bla")
  end

  def test_deserialize_returns_the_body_text
    @page.expects(:body).returns("abs")
    assert_equal({:text => "abs"}, @behavior.deserialize)
  end

  def test_deserialize_new
    @page.expects(:body).returns(nil)
    assert_equal({:text => nil}, @behavior.deserialize)
  end

  def test_render_renders_using_preparsed_template
    context = mock("context")
    @template.expects(:render!).with(context).returns(:my_rendered_text)
    assert_equal :my_rendered_text, @behavior.render(context)
  end
end
