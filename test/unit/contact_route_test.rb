require File.dirname(__FILE__) + '/../test_helper'

class BasicContactRouteValidationTest < Test::Unit::TestCase
  def setup
    @routable = Party.new
    @route = ContactRoute.new(:routable => @routable, :name => "Office")
  end

  # This test should fail, unless we save the route, in which case we can't
  # make ContactRoute abstract
  def test_xfail_valid_with_name_and_routable
    @route.valid?
    assert_raises(Test::Unit::AssertionFailedError) do
      assert @route.valid?, @route.errors.full_messages.join(", ")
    end
  end

  def test_route_name_defaults_to_main
    @route.name = nil
    @route.valid? # Run validations
    assert_equal "Main", @route.name
  end

  def test_invalid_without_routable
    @route.routable = nil
    assert !@route.valid?
    assert_match /can't be blank/, @route.errors.on(:routable_id).to_s
  end
end
