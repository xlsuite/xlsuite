require File.dirname(__FILE__) + "/../test_helper"

class AssetsControllerTest < ActionController::TestCase
  should_route :get, "/z/123.jpg", :action => :download, :filename => "123.jpg"
  should_route :get, "/admin/assets/123/download", :action => :download, :id => 123

  context "A public image asset" do
    setup do
      @image = fixture_file_upload("pictures/large.jpg", "image/jpeg", true)
      @asset = accounts(:wpul).assets.create!(:uploaded_data => @image)
    end

    context "with a GET to /admin/assets/__ID__/download" do
      setup do
        get :download, :id => @asset.id
      end

      should_respond_with :redirect
      should_assign_to :asset
      should_not_set_the_flash

      should_redirect_to "@asset.authenticated_s3_url"
    end
  end

  context "A private image asset" do
    setup do
      @image = fixture_file_upload("pictures/large.jpg", "image/jpeg", true)
      @asset = accounts(:wpul).assets.create!(:uploaded_data => @image)
      @asset.readers << groups(:staff_members) # Bob is part of Staff Members
    end

    context "with an anonymous user accessing the system" do
      context "with a GET to /admin/assets/__ID__/download" do
        setup do
          get :download, :id => @asset.id
        end

        should_respond_with :missing
        should_assign_to :asset
        should_not_set_the_flash
      end
    end

    context "with John accessing the system" do
      setup do
        login! :john
      end

      context "with a GET to /admin/assets/__ID__/download" do
        setup do
          get :download, :id => @asset.id
        end

        should_respond_with :missing
        should_assign_to :asset
        should_not_set_the_flash
      end
    end

    context "with Bob accessing the system" do
      setup do
        login! :bob
      end

      context "with a GET to /admin/assets/__ID__/download" do
        setup do
          get :download, :id => @asset.id
        end

        should_respond_with :redirect
        should_assign_to :asset
        should_not_set_the_flash

        should_redirect_to "@asset.authenticated_s3_url"
      end
    end
  end
end
