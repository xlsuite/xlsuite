require File.dirname(__FILE__) + "/../../test_helper"

class AddTagActionTest < Test::Unit::TestCase
  setup do
    @mock_party = mock("party")
  end

  context "An AddTagAction configured to add 'newsletter-week-1'" do
    setup do
      @action = AddTagAction.new
      @action.tag_name = "newsletter-week-1"
    end

    should "call \#tag with 'newsletter-week-1' on the selected party" do
      @mock_party.expects(:tag).with("newsletter-week-1")
      @action.run_against(@mock_party)
    end

    should "call \#tag with 'newsletter-week-1' on the selected parties" do
      @mock_party.expects(:tag).with("newsletter-week-1")
      @mock_party1 = mock("party")
      @mock_party1.expects(:tag).with("newsletter-week-1")
      @action.run_against([@mock_party, @mock_party1])
    end
  end
end
