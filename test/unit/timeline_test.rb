require File.dirname(__FILE__) + '/../test_helper'

class TimelineTest < Test::Unit::TestCase
  setup do
    @account = accounts(:wpul)
  end

  should "build valid timelines from the model builder" do
    assert build_timeline.valid?, "ModelBuilder\#hash_for_timeline looks like it's invalid"
  end

  context "A new timeline" do
    setup do
      @timeline = @account.timelines.build
    end

    should "have a subject" do
      assert_nothing_raised do
        @timeline.subject = parties(:bob)
      end
    end

    should "have an action" do
      assert_nothing_raised do
        @timeline.action = "create"
      end
    end
  end

  context "Timeline\#events_between" do
    context "with 2 events seconds apart" do
      setup do
        @party = create_party!
        @create = @party.account.timelines.create!(:subject => @party, :action => "create", :created_at => 2.minutes.ago.utc)
        @update = @party.account.timelines.create!(:subject => @party, :action => "update", :created_at => 1.minute.ago.utc)
      end

      should "return both events, in order, when asking for a range of time larger than the real time the events occured at" do
        assert_equal [@create, @update], Timeline.events_between(5.minutes.ago.utc .. Time.now.utc)
      end

      should "return both events, including virtual timeline events" do
        assert_equal [VirtualTimeline.at(5.minutes.ago), VirtualTimeline.at(4.minutes.ago), VirtualTimeline.at(3.minutes.ago),
              VirtualTimeline.at(2.minutes.ago), VirtualTimeline.at(1.minute.ago), VirtualTimeline.at(0.minutes.ago), @create, @update].sort_by(&:created_at),
              Timeline.events_between(5.minutes.ago.utc .. Time.now.utc, :with_virtual_events => true)
      end
    end
  end
end
