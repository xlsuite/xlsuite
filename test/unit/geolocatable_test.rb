require File.dirname(__FILE__) + "/../test_helper"

class GeolocatableTest < Test::Unit::TestCase
  include Geolocatable::ClassMethods

  context "#map_geo_unit" do
    should "return :miles when sent 'm'" do
      assert_equal :miles, map_geo_unit("m")
    end

    should "return :miles when sent 'M'" do
      assert_equal :miles, map_geo_unit("M")
    end

    should "return :miles when sent 'mile'" do
      assert_equal :miles, map_geo_unit("mile")
    end

    should "return :miles when sent 'miles'" do
      assert_equal :miles, map_geo_unit("miles")
    end

    should "return :miles when sent :m" do
      assert_equal :miles, map_geo_unit(:m)
    end

    should "return :miles when sent :mile" do
      assert_equal :miles, map_geo_unit(:mile)
    end

    should "return :miles when sent :miles" do
      assert_equal :miles, map_geo_unit(:miles)
    end

    should "return :kilometers when sent 'km'" do
      assert_equal :kilometers, map_geo_unit("km")
    end

    should "return :kilometers when sent 'KM'" do
      assert_equal :kilometers, map_geo_unit("KM")
    end

    should "return :kilometers when sent 'kilometer'" do
      assert_equal :kilometers, map_geo_unit("kilometer")
    end

    should "return :kilometers when sent 'kilometers'" do
      assert_equal :kilometers, map_geo_unit("kilometers")
    end

    should "return :kilometers when sent :km" do
      assert_equal :kilometers, map_geo_unit(:km)
    end

    should "return :kilometers when sent :kilometer" do
      assert_equal :kilometers, map_geo_unit(:kilometer)
    end

    should "return :kilometers when sent :kilometers" do
      assert_equal :kilometers, map_geo_unit(:kilometers)
    end

    should "raise an ArgumentError when sent nil" do
      assert_raise ArgumentError do
        map_geo_unit(nil)
      end
    end

    should "raise an ArgumentError when sent the empty string" do
      assert_raise ArgumentError do
        map_geo_unit("")
      end
    end

    should "raise an ArgumentError when sent an unrecognized option" do
      assert_raise ArgumentError do
        map_geo_unit("ads")
      end
    end
  end
end
