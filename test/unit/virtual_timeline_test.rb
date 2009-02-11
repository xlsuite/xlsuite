require File.dirname(__FILE__) + '/../test_helper'

class VirtualTimelineTest < Test::Unit::TestCase
  context "VirtualTimeline\#at" do
    should "set the number of seconds to zero" do
      assert VirtualTimeline.at(Time.now).created_at.sec.zero?
    end

    should "set the number of microseconds to zero" do
      assert VirtualTimeline.at(Time.now).created_at.usec.zero?
    end

    should "set the time to UTC" do
      assert VirtualTimeline.at(Time.now).created_at.utc_offset.zero?
    end
  end

  context "Two VirtualTimeline events that occured on the same moment" do
    setup do
      @t0 = VirtualTimeline.at(Time.now)
      @t1 = VirtualTimeline.at(Time.now)
    end

    should "be equal when the times are equal" do
      assert @t0 == @t1
    end

    should "have an equal hash" do
      assert_equal @t0.hash, @t1.hash
    end
  end
end
