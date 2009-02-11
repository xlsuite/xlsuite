require File.dirname(__FILE__) + '/../test_helper'
require 'products_controller'

# Re-raise errors caught by the controller.
class ProductsController; def rescue_action(e) raise e end; end

class ProductsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProductsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @account = Account.find(:first)
    @product1 = @account.products.create!(:name => "test product 1")
    @owner = @account.parties.find(:first)
    @product1.creator = @owner
    @product1.save!
    
    @asset = Asset.create!(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"), :owner => @owner)
    @asset_ids = @account.assets.map(&:id)
  end

  context "Non logged-in user trying to" do
    context "update a product" do
      setup do
        post :update, :id => @product1.id, :product => {:name => "rabbit"}, :login_redirect => "/login_redirect"
      end
      
      should "get redirected to params[:login_redirect]" do
        assert_redirected_to "/login_redirect"
      end
    end
    
    context "delete a product" do
      setup do
        delete :destroy, :id => @product1.id, :login_redirect => "/login_redirect"
      end
      
      should "get redirected to params[:login_redirect]" do
        assert_redirected_to "/login_redirect"
      end
    end
    
    context "attach assets to a product" do
      setup do
        post :attach_assets, :id => @product1.id, :login_redirect => "/login_redirect", :asset_ids => @asset_ids.join(", ")
      end
      
      should "get redirected to params[:login_redirect]" do
        assert_redirected_to "/login_redirect"
      end
    end

    context "detach assets from a product" do
      setup do
        View.create!(:asset => @asset, :attachable => @product1)
        post :detach_assets, :id => @product1.id, :asset_ids => @asset.id.to_s, :login_redirect => "/login_redirect"
      end
      
      should "get redirected to params[:login_redirect]" do
        assert_redirected_to "/login_redirect"
      end
    end
  end
  
  context "A logged in user" do
    context "who did not create a product trying to" do
      setup do
        @party = @account.parties.create!
        @party.confirmed = true
        @party.save!
        login_with_no_permissions!(@party)
      end
      
      context "update the product" do
        setup do
          post :update, :id => @product1.id, :product => {:name => "rabbit"}, :unauthorized_redirect => "/unauthorized_redirect"
        end
        
        should "get redirected to params[:unauthorized_redirect]" do
          assert_redirected_to "/unauthorized_redirect"
        end
      end

      context "delete the product" do
        setup do
          delete :destroy, :id => @product1.id, :unauthorized_redirect => "/unauthorized_redirect"
        end
        
        should "get redirected to params[:unauthorized_redirect]" do
          assert_redirected_to "/unauthorized_redirect"
        end
      end

      context "attach assets to a product" do
        setup do
          post :attach_assets, :id => @product1.id, :unauthorized_redirect => "/unauthorized_redirect", :asset_ids => @asset_ids.join(", ")
        end
        
        should "get redirected to params[:unauthorized_redirect]" do
          assert_redirected_to "/unauthorized_redirect"
        end
      end
      
      context "detach assets from a product" do
        setup do
          View.create!(:asset => @asset, :attachable => @product1)
          post :detach_assets, :id => @product1.id, :asset_ids => @asset.id.to_s, :unauthorized_redirect => "/unauthorized_redirect"
        end
        
        should "get redirected to params[:unauthorized_redirect]" do
          assert_redirected_to "/unauthorized_redirect"
        end
      end
    end
    
    context "who created a product trying to" do
      setup do
        login_with_no_permissions!(@owner)
      end
      
      context "update the product" do
        setup do
          put :update, :id => @product1.id, 
            :product => {
              :name => "rabbit", 
              :polygons => {"0" => {:points => "[[1,2],[3,4]]", :open => "1"}, "1" => {:points => "[[5,6],[7,8]]", :open => "0"}}
            }, 
            :next => "/next"
          @product1.reload
        end
        
        should "update the product name correctly" do
          assert_equal "rabbit", @product1.name
        end
        
        should "update the polygons correctly" do
          assert_equal [[1,2],[3,4]], @product1.polygons.first.points
          assert_equal true, @product1.polygons.first.open
          assert_equal [[5,6],[7,8]], @product1.polygons.last.points
          assert_equal false, @product1.polygons.last.open
        end
        
        should "get redirected to params[:next]" do
          assert_redirected_to "/next"
        end
      end

      context "delete the product" do
        setup do
          @product_count = Product.count
          delete :destroy, :id => @product1.id, :next => "/next"
        end
        
        should "get redirected to params[:next]" do
          assert_redirected_to "/next"
        end
        
        should "destroy the product correctly" do
          assert_equal @product_count-1,  Product.count
        end   
      end
      
      context "attach assets to the product" do
        context "by specifying asset_ids" do
          setup do
            assert_equal 0, @product1.views.count
            post :attach_assets, :id => @product1.id, :next => "/next", :asset_ids => @asset_ids.join(", ")
          end
          
          should "get redirected to params[:next]" do
            assert_redirected_to "/next"
          end
          
          should "attach the assets to the product correctly" do
            assert_equal @asset_ids.size, @product1.reload.views.count
          end
        end
        
        context "by passing in files" do
          setup do
            post :attach_assets, :id => @product1.id, :next => "/next", 
              :files => {"0" => {:uploaded_data => fixture_file_upload("pictures/large.jpg"), :title => "large picture"}}
          end
          
          should "get redirected to params[:next]" do
            assert_redirected_to "/next"
          end
          
          should "attach the assets to the product correctly" do
            assert_equal 1, @product1.reload.views.count
          end
        end 
      end
      
      context "detach assets" do
        context "that are related to the product" do
          setup do
            View.create!(:asset => @asset, :attachable => @product1)
            post :detach_assets, :id => @product1.id, :asset_ids => @asset.id.to_s, :next => "/next"
          end
        
          should "get redirected to params[:next]" do
            assert_redirected_to "/next"
          end
          
          should "detach the assets from the product correctly" do
            assert_equal 0, @product1.reload.views.count
          end
        end
        
        context "that are not related to the product" do
          setup do
            new_asset = Asset.create!(:account => @account, :uploaded_data => fixture_file_upload("pictures/large.jpg"), :owner => @owner)
            View.create!(:asset => @asset, :attachable => @product1)
            post :detach_assets, :id => @product1.id, :asset_ids => [@asset.id, new_asset.id].join(","), :next => "/next", :return_to => "/return_to"
          end
          
          should "get redirected to params[:return_to]" do
            assert_redirected_to "/return_to"
          end
          
          should "not detach any assets" do
            assert_equal 1, @product1.reload.views.count
          end
        end       
      end
    end
  end
end
