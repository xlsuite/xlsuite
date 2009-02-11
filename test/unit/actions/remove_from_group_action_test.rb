require File.dirname(__FILE__) + "/../../test_helper"

class RemoveFromGroupActionTest < Test::Unit::TestCase
  setup do
    @mock_party = mock("party")
    @group = groups(:access)
  end

  context "A RemoveFromGroupAction configured to remove group labelled access" do
    setup do
      @action = RemoveFromGroupAction.new
      @action.group_id = @group.id

      @mock_party.stubs(:member_of?).returns(true)
      @mock_party.stubs(:groups).returns(@groups_proxy = mock("groups proxy"))
      @groups_proxy.stubs(:delete)
    end

    should "call \#groups.delete on the selected party" do
      Group.stubs(:find).returns(mock_group = mock("group"))
      @mock_party.expects(:groups).returns(@groups_proxy)
      @groups_proxy.expects(:delete).with(mock_group)
      @action.run_against(@mock_party)
    end    
  end
end
