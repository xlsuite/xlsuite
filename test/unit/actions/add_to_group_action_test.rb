require File.dirname(__FILE__) + "/../../test_helper"

class AddToGroupActionTest < Test::Unit::TestCase
  setup do
    @mock_party = mock("party")
    @group = groups(:access)
  end

  context "An AddToGroupAction configured to add group labelled access" do
    setup do
      @action = AddToGroupAction.new
      @action.group_id = @group.id
      Group.stubs(:find).returns(@mock_group = mock("group"))
      @mock_party.stubs(:groups).returns(@groups_proxy = mock("groups_proxy"))
    end

    should "call \#groups << on the selected party" do
      @mock_party.stubs(:member_of?).returns(false)
      @mock_party.expects(:groups).returns(@groups_proxy)
      @groups_proxy.expects("<<".to_sym).with(@mock_group)
      @action.run_against(@mock_party)
    end
  end
end
