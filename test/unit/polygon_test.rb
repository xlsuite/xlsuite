require File.dirname(__FILE__) + '/../test_helper'

class PolygonTest < Test::Unit::TestCase
  context "Simple square of size 2" do
    setup do
      @polygon = Polygon.new(:points => [[0,0],[0,2],[2,2],[2,0]], :account => accounts(:wpul))
    end

    should "include point(1.88,0.23)" do
      assert @polygon.include?(1.88,0.23)
    end

    should "not include point(3.5, 1)" do
      deny @polygon.include?(3.5, 1)
    end
  end

  context "Complex polygon" do
    setup do
      @polygon = Polygon.new(:points => [[-3,-3],[-2,4],[0,3],[-1,1],[-1,-1],[2,3],[5,3],[5,-2],[1,-2],[2,2],[4,2],[2,-4]])
    end

    should "include point(-1,-2)" do 
      assert @polygon.include?(-1,-2)
    end

    should "include point(4,-1)" do 
      assert @polygon.include?(4,-1)
    end

    should "include point(2,2)" do 
      assert @polygon.include?(2,2)
    end

    should "include point(2,-3.99)" do 
      assert @polygon.include?(2,-3.99)
    end

    should "not include point(0,1)" do 
      deny @polygon.include?(0,1)
    end

    should "not include point(2,-1)" do 
      deny @polygon.include?(2,0)
    end
  end

  context "Converting a string of points to an array" do
    should "return an array of points" do
      assert_equal [[1,2.32],[2,0.3],[4.32,-0.015]], Polygon.str_to_array("[ [1, 2.32] ,[2,.3],[ 4.32,-.015]]")
    end

    should "return nil if string is \#blank?" do
      assert_nil Polygon.str_to_array("")
    end
  end
  
  context "Initializing polygons with String as points" do
    setup do
      @polygon = Polygon.new(:description => "test Polygon", :account => accounts(:wpul), :points => "[ [1, 2.32] ,[2,.3],[ 4.32,-.015]]")
    end

    context "before save" do
      should "return points as array" do
        assert_equal [[1,2.32],[2,0.3],[4.32,-0.015]], @polygon.points
      end
    end

    context "after save" do
      setup do
        @polygon.save!
      end

      context "after reload" do
        setup do
          @polygon.reload
        end

        should "return points as array" do
          assert_equal [[1,2.32],[2,0.3],[4.32,-0.015]], @polygon.points
        end
      end

      should "return points as array" do
        assert_equal [[1,2.32],[2,0.3],[4.32,-0.015]], @polygon.points
      end
    end    
  end

  context "A triangular polygon" do
    setup do
      @polygon = accounts(:wpul).polygons.create!(:points => "[[1000, 1000], [1500, 2000], [500, 2000]]", :description => "Conditional area")
    end

    should "include a geocode in the center" do
      @geocode = Geocode.create!(:latitude => 1000, :longitude => 1500, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    should_eventually "include a geocode at the tip" do
      @geocode = Geocode.create!(:latitude => 1000, :longitude => 1000, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    should "include a geocode nearly at the tip" do
      @geocode = Geocode.create!(:latitude => 1000, :longitude => 1000.01, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    should "NOT include a geocode at the top-right" do
      @geocode = Geocode.create!(:latitude => 1500, :longitude => 1000, :zip => "J1J4J4")
      assert_does_not_include @geocode, @polygon.to_geocodes
    end

    should "NOT include a geocode outside the triangle" do
      @geocode = Geocode.create!(:latitude => 50, :longitude => -500, :zip => "J1J4J4")
      assert_does_not_include @geocode, @polygon.to_geocodes
    end
  end

  context "A square polygon" do
    setup do
      @polygon = accounts(:wpul).polygons.create!(:points => "[[1000, 1000], [1000, 2000], [2000, 2000], [2000, 1000]]", :description => "Conditional area")
    end

    should "include a geocode at the top-right corner" do
      @geocode = Geocode.create!(:latitude => 2000, :longitude => 2000, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    # This test fails because the crossing number code
    should_eventually "include a geocode at the top-left corner" do
      @geocode = Geocode.create!(:latitude => 2000, :longitude => 1000, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    should_eventually "include a geocode at the bottom-left corner" do
      @geocode = Geocode.create!(:latitude => 1000, :longitude => 1000, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    should "include a geocode at the bottom-right corner" do
      @geocode = Geocode.create!(:latitude => 2000, :longitude => 2000, :zip => "J1J4J4")
      assert_include @geocode, @polygon.to_geocodes
    end

    should "NOT include a geocode outside the box" do
      @geocode = Geocode.create!(:latitude => 50, :longitude => 50, :zip => "J1J4J4")
      assert_does_not_include @geocode, @polygon.to_geocodes
    end
  end
end
