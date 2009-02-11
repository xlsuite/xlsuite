require File.dirname(__FILE__) + '/../test_helper'
require 'pages_controller'

# Re-raise errors caught by the controller.
class PagesController; def rescue_action(e) raise e end; end

class PagesControllerTest < Test::Unit::TestCase
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(1)
    @bob = parties(:bob)
  end

  context "An authenticated user on the 'xlsuite.com' domain" do
    setup do
      @request.host = "xlsuite.com"
      @domain = @account.domains.create!(:name => "xlsuite.com")
      @domain = @account.domains.create!(:name => "xltester.com")

      @bob = login_with_no_permissions!(:bob)
      @layout = @account.layouts.create!(:title => "HTML", :body => "{{ page.body }}", :author => @bob)
      @page = @account.pages.create!(:title => "xlsuite home", :body => "xlsuite", :status => "published",
                                     :domain_patterns => "**", :creator => @bob, :fullslug => "", :layout => "HTML")
    end

    should "not view a draft page" do
      @page.update_attributes(:status => "draft")
      get :show, :path => []
      assert_response :missing
    end

    context "with the :edit_pages permission" do
      setup do
        @bob = login_with_permissions!(:bob, :edit_pages)
      end

      should "view a draft page" do
        @page.update_attributes(:status => "draft")
        get :show, :path => []
        assert_response :success
      end

      should "get the new page" do
        get :new
        assert_response :success
        assert_not_nil assigns(:page)
      end

      should "create a page" do
        post :create, :page => {:title => "new page title", :layout => "HTML", :behavior => "plain_text", :behavior_values => {:text => "page body"}}
        assert_not_nil @page = assigns(:page)
        assert_equal "new page title", @page.reload.title
      end

      should "create and redirect to index if the close button is used" do
        post :create, :page => {:title => "new page title", :layout => "HTML", :behavior => "plain_text", :behavior_values => {:text => "page body"}}, :commit => "close"
        assert_response :redirect
        assert_redirected_to pages_path
      end

      context "and an existing page" do
        setup do
          @page = @account.pages.create!(:title => "my page", :behavior => "plain_text", :behavior_values => {:text => "page body"}, :creator => @bob, :layout => "HTML")
        end

        should "copy the existing page when asking for a new child page" do
          Page.expects(:find).with(@page.id.to_s, anything).returns(@page)
          @page.expects(:copy).returns(@page)

          get :new, :parent_id => @page.id
          assert_response :success
          assert_template "new"
        end

        should "get the index page" do
          get :index
          assert_response :success
          assert_not_nil assigns(:pages)
          assert_include @page, assigns(:pages)
        end

        should "get the edit page" do
          get :edit, :id => @page.id
          assert_response :success
          assert_equal @page, assigns(:page)
        end

        should "update the page" do
          put :update, :id => @page.id, :page => {:title => "new title"}
          assert_equal "new title", @page.reload.title
        end

        should "update and redirect to index if the close button is used" do
          put :update, :id => @page.id, :page => {:title => "new title"}, :commit => "close"
          assert_response :redirect
          assert_redirected_to pages_path
        end

        should "destroy a page" do
          delete :destroy, :id => @page.id
          assert_response :redirect
          assert_redirected_to pages_path
        end

        should "update through xhr" do
          xhr :put, :update, :id => @page.id, :page => {:title => "new title"}
          assert_response :success
          assert_equal "new title", @page.reload.title
        end

        should "destroy through xhr" do
          xhr :delete, :destroy, :id => @page.id
          assert_response :success
          assert_template "destroy"
        end

        should "be able to get behavioral editor page" do
          get :behavior, :id => @page.id, :page => {:behavior => "products"}
          assert_response :success
          assert_template "_products"
        end

        should "create with a non-default behavior" do
          @pc = ProductCategory.new
          @pc.save(false)
          post :create, :page => {:title => "Featured Products", :layout => "HTML", :behavior => "products"},
                                  :behavior_values => {:product_category_id => @pc.id.to_s}

          assert_redirected_to edit_page_path(assigns(:page)) 
        end
      end
    end
  end

  context "An anonymous user on the 'xlsuite.com' domain" do
    setup do
      @request.host = "xlsuite.com"
      @domain = @account.domains.create!(:name => "xlsuite.com")
      @domain = @account.domains.create!(:name => "xltester.com")

      @layout = @account.layouts.create!(:title => "HTML", :body => "{{ page.body }}", :author => @bob)
      @page = @account.pages.create!(:title => "xlsuite home", :body => "xlsuite", :status => "published",
                                     :domain_patterns => "**", :creator => @bob, :fullslug => "", :layout => "HTML")
    end

    should "get the xlsuite.com specific page" do
      @page.update_attributes(:domain_patterns => "xlsuite.com")
      get :show, :path => []

      assert_response :success
      assert_equal @page, assigns(:page)
    end

    should "get a 404 when the only page is for xltester.com" do
      @page.update_attributes(:domain_patterns => "xltester.com")
      get :show, :path => []
      assert_response :missing
    end

    should "get the xlsuite.com page even if there is an xltester.com page" do
      @page.update_attributes(:domain_patterns => "xlsuite.com")
      page1 = @account.pages.create!(@page.attributes.stringify_keys.merge("domain_patterns" => "xltester.com"))
      get :show, :path => []
      assert_response :success
      assert_equal @page, assigns(:page)
      assert_match /xlsuite/, @response.body
    end
    
    should "be redirected if page requires ssl" do
      @page.update_attributes(:require_ssl => true)
      get :show, :path => []
      assert_response :redirect
    end
    
    should "be able to access a secure page with ssl" do
      @page.update_attributes(:require_ssl => true)
      @request.env["HTTPS"] = "on"
      get :show, :path => []
      assert_response :success
    end
  end
end
