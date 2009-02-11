require File.dirname(__FILE__) + "/../../test_helper.rb"

class XlSuite::RoutingTest < Test::Unit::TestCase
  def test_static_route_building
    expected_routes = {%r{\A/static\Z}i => {:pages => [37]}}
    assert_equal expected_routes, XlSuite::Routing.build("/static" => 37)
  end

  def test_one_component_dynamic_route
    expected_routes = {%r{\A/static/([^/]+)\Z}i => {:pages => [41, 42], :params => [:dynamic]}}
    assert_equal expected_routes, XlSuite::Routing.build("/static/:dynamic" => [41, 42])
  end

  def test_two_component_dynamic_route
    expected_routes = {%r{\A/blogs/([^/]+)/tags/([^/]+)\Z}i => {:pages => [47], :params => [:label, :tag]}}
    actual_routes = XlSuite::Routing.build("/blogs/:label/tags/:tag" => [47])
    assert_equal expected_routes, actual_routes,
    "Expected: #{expected_routes.keys.first.inspect}\nFound:    #{actual_routes.keys.first.inspect}"
  end

  def test_fullslug_normalized_to_have_a_slash_at_the_front
    expected_routes = {%r{\A/blog\Z}i => {:pages => [55]}}
    assert_equal expected_routes, XlSuite::Routing.build("blog" => [55])
  end

  def test_home_page_routing
    expected_routes = {%r{\A/\Z}i => {:pages => [55]}}
    assert_equal expected_routes, XlSuite::Routing.build("" => [55])
  end

  def test_can_build_many_routes_in_one_call
    expected_routes = {
      %r{\A/blogs\Z}i => {:pages => [13]},
      %r{\A/blogs/([^/]+)\Z}i => {:pages => [14], :params => [:label]},
      %r{\A/blogs/([^/]+)/tags/([^/]+)\Z}i => {:pages => [15], :params => [:label, :tag]}
    }

    actual_routes = XlSuite::Routing.build("/blogs" => 13, "/blogs/:label/tags/:tag" => 15, "/blogs/:label" => 14)
    assert_equal expected_routes, actual_routes
  end

  def test_can_constrain_parameter_to_specific_type
    expected_routes = {%r{\A/([\d]+)\Z}i => {:pages => [134], :params => [:year]}}
    actual_routes = XlSuite::Routing.build(":year" => {:pages => [134], :requirements => {:year => :digits}})
    assert_equal expected_routes, actual_routes
  end

  def test_can_constrain_to_real_world_types
    expected_routes = {%r{\A/archives/([1-9][\d]{3})/(0[1-9]|1[012]|[1-9])/(0[1-9]|[12]\d|3[01]|[1-9])/([\d]+)/([^/]+)\Z}i => {:pages => [134], :params => [:year, :month, :day, :id, :permalink]}}
    actual_routes = XlSuite::Routing.build("/archives/:year/:month/:day/:id/:permalink" => {:pages => [134], :requirements => {:year => :year, :month => :month, :day => :day, :id => :id, :permalink => :permalink}})
    assert_equal expected_routes, actual_routes
  end

  def test_can_recognize_a_static_route
    routes = XlSuite::Routing.build("/blog" => 13)
    expected = {:pages => [13], :params => {}}
    assert_equal expected, XlSuite::Routing.recognize("/blog", routes)
  end

  def test_recognizing_a_dynamic_route_returns_the_bound_parameter
    routes = XlSuite::Routing.build("/:label" => 131)
    expected = {:pages => [131], :params => {:label => "francois"}}
    assert_equal expected, XlSuite::Routing.recognize("/francois", routes)
  end

  context "A route set recognizing only '/blog'" do
    setup do
      @routes = XlSuite::Routing.build("/blog" => 13)
    end

    context "\#recognize" do
      should "return nil when attempting to recognize '/soggy'" do
        assert_nil XlSuite::Routing.recognize("/soggy", @routes)
      end
    end

    context "\#recognize!" do
      should "raise an XlSuite::Routing::RouteNotFound exception when recognizing '/soggy'" do
        assert_raise XlSuite::Routing::RouteNotFound do
          XlSuite::Routing.recognize!("/soggy", @routes)
        end
      end
    end
  end
end
