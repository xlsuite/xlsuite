require File.dirname(__FILE__) + '/../test_helper'
require 'domains_controller'

# Re-raise errors caught by the controller.
class DomainsController; def rescue_action(e) raise e end; end

class DomainsControllerTest < Test::Unit::TestCase
  def setup
    @controller = DomainsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @admin = login_with_no_permissions!(:bob)
    @account = accounts(:wpul)
    @domain = @account.domains.first
  end

  context "A non-superuser" do
    setup do
      @admin.superuser = false
      @admin.save!
    end

    context "editing his own account" do
      setup do
        @account.update_attributes!(:owner => @admin)
      end

      context "on GET /admin/domains" do
        setup do
          get :index
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'index' template" do
          assert_template "index"
        end

        should "make an @domains variable available to the view" do
          assert_kind_of Enumerable, assigns(:domains)
        end

        should "make a @paginator variable available to the view" do
          assert_not_nil assigns(:paginator)
        end

        should "only have this account's domains in the list" do
          assert_equal @account.domains.find(:all, :order => "name"), assigns(:domains)
        end
      end

      context "on GET /admin/domains/new" do
        setup do
          get :new
        end

        should "be successful" do
          assert_response :success
        end

        should "view the new template" do
          assert_template "new"
        end

        should "make a @domain available to the view" do
          assert_kind_of Domain, assigns(:domain)
        end
      end

      context "on POST /admin/domains with {'name' => 'my.domain.name', :price => ''}" do
        setup do
          post :create, :domain => {"name" => "my.domain.name", :price => ""}
        end

        should "redirect to domains_path" do
          assert_redirected_to domains_path
        end

        should "create a new domain under the owner's account" do
          assert_not_nil @account.domains.find_by_name("my.domain.name")
        end
      end

      context "on GET /admin/domains/__ID__/edit" do
        setup do
          get :edit, :id => @domain.id
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'edit' template" do
          assert_template "edit"
        end

        should "make the domain available to the view" do
          assert_equal @domain, assigns(:domain)
        end
      end

      context "on PUT /admin/domains/__ID__ with {'name' => 'my.domain.name', 'price' => '25 CAD'}" do
        setup do
          put :update, :id => @domain.id, :domain => {"name" => "my.domain.name", :price => "25 CAD"}
        end

        should "redirect to domains_path" do
          assert_redirected_to domains_path
        end
      end

      context "on DELETE /admin/domains/__ID__" do
        setup do
          delete :destroy, :id => @domain.id
        end

        should "remove the domain from the DB" do
          assert_raise ActiveRecord::RecordNotFound do
            @domain.reload
          end
        end

        should "redirect to domains_path" do
          assert_redirected_to domains_path
        end
      end
    end

    context "editing within his account with the :edit_domains permission" do
      setup do
        @account.update_attributes!(:owner => nil)
        @admin.append_permissions(:edit_domains)
      end

      context "on GET /admin/domains" do
        setup do
          get :index
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'index' template" do
          assert_template "index"
        end

        should "make an @domains variable available to the view" do
          assert_kind_of Enumerable, assigns(:domains)
        end

        should "make a @paginator variable available to the view" do
          assert_not_nil assigns(:paginator)
        end
      end

      context "on GET /admin/domains/new" do
        setup do
          get :new
        end

        should "be successful" do
          assert_response :success
        end

        should "view the new template" do
          assert_template "new"
        end

        should "make a @domain available to the view" do
          assert_kind_of Domain, assigns(:domain)
        end
      end

      context "on POST /admin/domains with {'name' => 'my.domain.name', :price => ''}" do
        setup do
          post :create, :domain => {"name" => "my.domain.name", :price => ""}
        end

        should "redirect to domains_path" do
          assert_redirected_to domains_path
        end

        should "create a new domain under the owner's account" do
          assert_not_nil @account.domains.find_by_name("my.domain.name")
        end
      end

      context "on GET /admin/domains/__ID__/edit" do
        setup do
          get :edit, :id => @domain.id
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'edit' template" do
          assert_template "edit"
        end

        should "make the domain available to the view" do
          assert_equal @domain, assigns(:domain)
        end
      end

      context "on PUT /admin/domains/__ID__ with {'name' => 'my.domain.name', 'price' => '25 CAD'}" do
        setup do
          put :update, :id => @domain.id, :domain => {"name" => "my.domain.name", :price => "25 CAD"}
        end

        should "redirect to domains_path" do
          assert_redirected_to domains_path
        end
      end

      context "on DELETE /admin/domains/__ID__" do
        setup do
          delete :destroy, :id => @domain.id
        end

        should "remove the domain from the DB" do
          assert_raise ActiveRecord::RecordNotFound do
            @domain.reload
          end
        end

        should "redirect to domains_path" do
          assert_redirected_to domains_path
        end
      end
    end

    context "editing within his account without the :edit_domains permission" do
      setup do
        @account.update_attributes!(:owner => nil)
      end

      context "on GET /admin/domains" do
        setup do
          get :index
        end

        should "be unauthorized" do
          assert_response :unauthorized
        end
      end

      context "on GET /admin/domains/new" do
        setup do
          get :new
        end

        should "be unauthorized" do
          assert_response :unauthorized
        end
      end

      context "on POST /admin/domains" do
        setup do
          post :create, :domain => {:name => "my.domain.name"}
        end

        should "be unauthorized" do
          assert_response :unauthorized
        end
      end

      context "on GET /admin/domains/__ID__/edit" do
        setup do
          get :edit, :id => @domain.id
        end

        should "be unauthorized" do
          assert_response :unauthorized
        end
      end

      context "on PUT /admin/domains/__ID__" do
        setup do
          put :update, :id => @domain.id, :domain => {:name => "my.domain.name"}
        end

        should "be unauthorized" do
          assert_response :unauthorized
        end
      end

      context "on DELETE /admin/domains/__ID__" do
        setup do
          delete :destroy, :id => @domain.id
        end

        should "be unauthorized" do
          assert_response :unauthorized
        end
      end
    end
  end

  context "A superuser" do
    setup do
      @admin.superuser = true
      @admin.save!
    end

    context "editing his account" do
      setup do
      end

      context "on GET /admin/domains/new" do
        setup do
          get :new
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'new' template" do
          assert_template "new"
        end

        should "make a domain available to the view" do
          assert_kind_of Domain, assigns(:domain)
        end
      end
    end

    context "editing another account" do
      setup do
        @account = create_account
        @domain = @account.domains.create!(:name => "my.name")
      end

      context "on GET /admin/domains" do
        setup do
          get :index, :account_id => @account.id
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'index' template" do
          assert_template "index"
        end

        should "make an @domains variable available to the view" do
          assert_kind_of Enumerable, assigns(:domains)
        end

        should "make a @paginator variable available to the view" do
          assert_not_nil assigns(:paginator)
        end

        should "have the single domain from this account in the list" do
          assert_equal [@domain], assigns(:domains)
        end
      end

      context "on GET /admin/accounts/__ID__/domains/new" do
        setup do
          get :new, :account_id => @account.id
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'new' template" do
          assert_template "new"
        end

        should "make a domain available to the view" do
          assert_kind_of Domain, assigns(:domain)
        end

        should "link the domain to the Account" do
          assert_equal @account, assigns(:domain).account
        end
      end

      context "on POST /admin/accounts/__ID__/domains with {'name' => 'my.domain.name', :price => ''}" do
        setup do
          post :create, :account_id => @account.id, :domain => {"name" => "my.domain.name", :price => ""}
        end

        should "redirect to edit_account_path(@account)" do
          assert_redirected_to edit_account_path(@account)
        end

        should "create a new domain under the owner's account" do
          assert_not_nil @account.domains.find_by_name("my.domain.name")
        end
      end

      context "on GET /admin/accounts/__ID__/domains/__ID__/edit" do
        setup do
          get :edit, :account_id => @account.id, :id => @domain.id
        end

        should "be successful" do
          assert_response :success
        end

        should "render the 'edit' template" do
          assert_template "edit"
        end

        should "make the domain available to the view" do
          assert_equal @domain, assigns(:domain)
        end
      end

      context "on PUT /admin/accounts/__ID__/domains/__ID__ with {'name' => 'my.domain.name', 'price' => '25 CAD'}" do
        setup do
          put :update, :account_id => @account.id, :id => @domain.id, :domain => {"name" => "my.domain.name", :price => "25 CAD"}
        end

        should "redirect to edit_account_path(@account)" do
          assert_redirected_to edit_account_path(@account)
        end
      end

      context "on DELETE /admin/accounts/__ID__/domains/__ID__" do
        setup do
          delete :destroy, :account_id => @account.id, :id => @domain.id
        end

        should "remove the domain from the DB" do
          assert_raise ActiveRecord::RecordNotFound do
            @domain.reload
          end
        end

        should "redirect to edit_account_path(@account)" do
          assert_redirected_to edit_account_path(@account)
        end
      end
    end
  end
end
