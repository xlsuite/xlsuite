require File.dirname(__FILE__) + '/../test_helper'

class ListingDataTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @listing = @account.listings.create!
  end

  def test_uuid_was_generated
    assert_not_nil @listing.uuid
  end

  def test_uuid_respects_uuid_format
    assert_equal @listing.uuid, UUID.parse(@listing.uuid).to_s
  end
  
  def test_destroy_remove_listing_address_contact_route
    @listing.address = @account.address_contact_routes.build
    assert @listing.save
    assert_difference AddressContactRoute, :count, -1 do
      assert @listing.destroy
    end
  end
  
  context "Listing with files attached to it" do
    setup do
      @asset_one = Asset.new(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"), :owner => parties(:bob))
      @asset_two = Asset.new(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"), :owner => parties(:bob))
      @asset_one.save
      @asset_two.save
      parties(:bob).views.create(:asset => @asset_two)
      assert @listing.views.create(:asset => @asset_one)
      assert @listing.views.create(:asset => @asset_two)
    end
    
    context "gets deleted" do
      setup do
        @listing.destroy
      end
      
      should "destroy assets that are related only to the destroyed listing" do
        assert_raise ActiveRecord::RecordNotFound do
          Asset.find(@asset_one.id)
        end
        assert_not_nil Asset.find_by_id(@asset_two.id)
      end
    end
  end
end
