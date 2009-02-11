require File.dirname(__FILE__) + "/../../test_helper"

class RemoveTagActionTest < Test::Unit::TestCase
  setup do
    @mock_party = mock("party")
  end

  context "A RemoveTagAction configured to remove 'newsletter-week-1'" do
    setup do
      @action = RemoveTagAction.new
      @action.tag_name = "newsletter-week-1"

      @mock_party.stubs(:tags).returns(@tags_proxy = mock("tags proxy"))
      @tags_proxy.stubs(:remove)
    end

    should "find or create the tag" do
      Tag.expects(:find_or_create_by_name).with("newsletter-week-1").returns(mock_tag = mock("tag"))
      @action.run_against(@mock_party)
    end

    should "call \#tags.remove(Tag.find_or_create_by_name('newsletter-week-1'))" do
      Tag.stubs(:find_or_create_by_name).returns(mock_tag = mock("tag"))
      @mock_party.expects(:tags).returns(@tags_proxy)
      @tags_proxy.expects(:remove).with(mock_tag)
      @action.run_against(@mock_party)
    end
  end
end
