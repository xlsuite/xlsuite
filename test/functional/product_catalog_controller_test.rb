require File.dirname(__FILE__) + '/../test_helper'
require 'product_catalog_controller'

# Re-raise errors caught by the controller.
class ProductCatalogController; def rescue_action(e) raise e end; end

class ProductCatalogControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProductCatalogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
    ProductCategory.delete_all(["name=?", "Profile"])
    @profile_root_product_category = @account.product_categories.create!(:name => "Profile")
    config = ProductCategoryConfiguration.create!(:name => "profile_root_product_category")
    config.set_value!(@profile_root_product_category)
  end

  context "Non logged-in users" do
    setup do
      @product = @account.products.find(:first)
    end

    context "trying to access add_product action" do
      context "specifying login_redirect" do
        setup do
          post :add_product, :id => @product.id, :login_redirect => "/login"
        end

        should "get redirected to the login_redirect" do
          assert_redirected_to "/login"
        end
      end

      context "without specifying login_redirect" do
        setup do
          post :add_product, :id => @product.id
        end

        should "be redirected to /sessions/new" do
          assert_redirected_to "/sessions/new"
        end
      end
    end
  end

  context "Logged-in user that doesn't have his/her product category setup before" do
    setup do
      @product = @account.products.find(:first)
      @party = @account.parties.create!
      login_with_no_permissions!(@party)
      @product_category_count = ProductCategory.count
    end

    context "accessing add_product action" do
      context "without providing category_id params" do
        setup do
          post :add_product, :id => @product.id, :next => "/next", :return_to => "/return_to"
        end

        should "assign a new product category to the logged in user" do
          assert_equal @product_category_count + 1, ProductCategory.count
          assert @party.reload.product_category
        end

        should "be redirected to params next" do
          assert_redirected_to "/next"
        end
      end

      context "with faulty category_id params (obviously the user's product category doesn't have any children since it has not been setup)" do
        setup do
          ProductCategory.delete_all(["name=?", "Aloha"])
          @parent_category = @account.product_categories.create!(:name => "Aloha")
          @product_category_count = ProductCategory.count
          post :add_product, :id => @product.id, :category_id => @parent_category.id, :next => "/next", :return_to => "/return_to"
        end

        should "still initialize the user product category" do
          assert_equal @product_category_count + 1, ProductCategory.count
        end

        should "get redirected to params[:return_to]" do
          assert_redirected_to "/return_to"
        end
      end
    end

    context "accessing remove_product action" do
      context "removing a product that doesn't exist in his/her category (well his/her category hasn't been setup at this point)" do
        setup do
          post :remove_product, :id => @product.id, :return_to => "/return_to"
        end

        should "still initialize the user product category" do
          assert_equal @product_category_count + 1, ProductCategory.count
        end

        should "get redirected to params[:return_to]"do
          assert_redirected_to "/return_to"
        end
      end
    end
  end

  context "Logged-in user that has his/her product category setup" do
    setup do
      @product = @account.products.find(:first)
      @party = @account.parties.create!
      login_with_no_permissions!(@party)
      @party_root_pc = @party.create_own_product_category!
      @account.product_categories.find_all_by_name("Aloha").map(&:destroy)
      @child_pc = @account.product_categories.create!(:name => "Aloha")
      @child_pc.parent = @party_root_pc
      @child_pc.save!
    end

    context "adding a product to his/her root profile product category" do
      setup do
        post :add_product, :id => @product.id, :next => "/next"
      end

      should "add the product properly" do
        assert @party_root_pc.reload.products.find(@product.id)
      end

      should "get redirected to params[:next]" do
        assert_redirected_to "/next"
      end
    end

    context "adding a product to one of his/her root profile product category's children" do
      setup do
        post :add_product, :id => @product.id, :category_id => @child_pc.id, :next => "/next"
      end

      should "add the product properly" do
        assert @child_pc.reload.products.find(@product.id)
      end

      should "get redirected to params[:next]" do
        assert_redirected_to "/next"
      end
    end

    context "trying to remove a non-existant product from his/her" do
      context "root product category" do
        setup do
          post :remove_product, :id => @product.id, :return_to => "/return_to"
        end

        should "get redirected to params[:return_to]" do
          assert_redirected_to "/return_to"
        end
      end

      context "children product category" do
        setup do
          post :remove_product, :id => @product.id, :category_id => @child_pc.id, :return_to => "/return_to"
        end

        should "get redirected to params[:return_to]" do
          assert_redirected_to "/return_to"
        end
      end
    end

    context "removing a product from his/her" do
      context "root profile product category" do
        setup do
          @party_root_pc.products << @product
          post :remove_product, :id => @product.id, :next => "/next"
        end

        should "get redirected to params[:next]" do
          assert_redirected_to "/next"
        end
      end

      context "children profile product category" do
        setup do
          @child_pc.products << @product
          post :remove_product, :id => @product.id, :category_id => @child_pc.id, :next => "/next"
        end

        should "get redirected to params[:next]" do
          assert_redirected_to "/next"
        end
      end
    end
    
    context "trying to create a product category" do
      context "under the profile product category" do
        setup do
          post :create_category, :product_category => {:name => "Child1", :description => "I am child one", :tag_list => "test"}, :next => "/next"
        end
        
        should "create the new product category properly" do
          assert_equal 2, @party_root_pc.reload.children.count
          child1 = @party_root_pc.children.find_by_name("Child1")
          assert_equal "Child1", child1.name
          assert_equal "I am child one", child1.description
          assert_equal "test", child1.tag_list
        end
        
        should "get redirected to params[:next]" do
          assert_redirected_to "/next"
        end
      end
      
      context "under a child product category" do
        setup do
          post :create_category, :parent_id => @child_pc.id, :product_category => {:name => "GrandChild1", :description => "I am grand child one", :tag_list => "test"}, :next => "/next"
        end
        
        should "add the new product category properly" do
          assert_equal 1, @party_root_pc.reload.children.count
          assert_equal 1, @child_pc.reload.children.count
          grandchild1 = @child_pc.children.find(:first)
          assert_equal "GrandChild1", grandchild1.name
          assert_equal "I am grand child one", grandchild1.description
          assert_equal "test", grandchild1.tag_list
        end
        
        should "get redirected to params[:next]" do
          assert_redirected_to "/next"
        end
      end
    end
    
    context "trying to delete a product category" do
      context "under the profile product category" do
        setup do
          post :delete_category, :id => @child_pc.id, :next => "/next"
        end
        
        should "be redirected to params[:next]" do
          assert_redirected_to "/next"
        end
        
        should "delete the product category properly" do
          assert_equal 0, @party_root_pc.children.count
          assert_raise ActiveRecord::RecordNotFound do
            @child_pc.reload
          end
        end
      end
      
      context "that is not a category inside his/her profile product catalog" do
        setup do
          @new_pc = @account.product_categories.create!(:name => "Test1 New Product Category")
          @product_category_count = ProductCategory.count
          post :delete_category, :id => @new_pc.id, :return_to => "/return_to"
        end
        
        should "be redirected to params[:return_to]" do
          assert_redirected_to "/return_to"
        end
        
        should "not delete any category" do
          assert_equal @product_category_count, ProductCategory.count
        end
      end
    end
  end
end
