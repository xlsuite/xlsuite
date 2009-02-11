require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class Thing < ActiveRecord::Base
  
  def new_record?; false; end
  
  def id; 1; end
  
end

class PeopleThing < ActiveRecord::Base

  def new_record?; true; end
  
end

class TestDomId < Test::Unit::TestCase

  def test_dom_id
    thing = Thing.new
    assert_equal 'thing_1', thing.dom_id
  end
  
  def test_new
    pt = PeopleThing.new
    assert_equal 'people_thing_new', pt.dom_id
    assert_equal 'many_people_thing_new', pt.dom_id('many')
  end
  
end
