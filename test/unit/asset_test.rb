require File.dirname(__FILE__) + "/../test_helper"

class AssetTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
  end

  context "A new asset" do
    setup do
      @asset = Asset.new(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"), :owner => parties(:bob))
    end

    should "calculate an Etag during the save" do
      @asset.save(false)
      assert_not_nil @asset.etag
    end

    should "be invalid when no account assigned" do
      @asset.account = nil
      deny @asset.valid?
    end

    should "return 'widthxheight' when sent #geometry" do
      @asset.width, @asset.height = 323, 125
      assert_equal "323x125", @asset.geometry
    end

    should "increment the already existing counter when the filename is already taken" do
      Asset.create!(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"), :filename => "large-1.jpg")
      @asset.filename = "large-1.jpg"
      @asset.save!
      assert_equal "large-2.jpg", @asset.filename
    end

    should "generate a new filename when the filename conflicts with an existing asset" do
      Asset.create!(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"))
      @asset.save!
      assert_equal "large-1.jpg", @asset.filename
    end

    should "generate a new filename when the filename conflicts with more than one asset" do
      Asset.create!(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"))
      Asset.create!(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"))
      @asset.save!
      assert_equal "large-2.jpg", @asset.filename
    end

    should "be taggable" do
      @asset.tag_list = "a b c"
      @asset.save!
      assert_equal ["a", "b", "c"], @asset.reload.tags.map(&:name).sort
    end

    context "that was saved" do
      setup do
        @asset.save!
      end

      should "provide it's etag value as an HTTP header in \#http_headers" do
        assert_equal @asset.etag, @asset.http_headers["Etag"]
      end

      should "NOT recalculate the etag when the uploaded data hasn't changed" do
        etag = @asset.etag
        @asset.title = "abc"
        @asset.save!
        assert_equal etag, @asset.reload.etag
      end

      should "recalculate the etag when the asset's data is changed" do
        etag = @asset.etag
        @asset.uploaded_data = fixture_file_upload("pictures/1.jpg")
        @asset.save!
        assert_not_equal etag, @asset.reload.etag
      end

      should "be taggable" do
        @asset.tag_list = "blue high"
        @asset.save!
        assert_equal %w(blue high).sort, @asset.reload.tags.map(&:name).sort
      end
    end
  end
end
