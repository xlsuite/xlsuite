require File.dirname(__FILE__) + '/../test_helper'

class ProfileTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @party = @account.parties.find(:first)
    @profile = @party.to_new_profile
    @profile.save!
    @party.profile = @profile
    @party.save!
    @party.copy_contact_routes_to_profile!
  end
  
  context "Calling reader methods that does not exist in Profile object" do
    setup do
      @profile.info.merge(:aloha => "my name is harman sandjaja")
      @profile.save!
    end
    
    should "extract value from the Profile#info hash" do
      assert "my name is harman sandjaja", @profile.aloha
    end  
  end
  
  context "Calling writer method that does not exist in the Profile object" do
    setup do
      @profile.attributes = {:aloha => [["my name is harman", "abc"]], :nyam => "harman sandjaja"}
      @profile.nyampoo = 123
      @profile.save!
    end
    
    should "set the correct hash in the Profile#info" do
      assert_equal [["my name is harman", "abc"]], @profile.aloha
      assert_equal "harman sandjaja", @profile.nyam
      assert_equal 123, @profile.nyampoo
    end
  end
end
