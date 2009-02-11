require File.dirname(__FILE__) + '/../test_helper'
require 'invoices_controller'

# Re-raise errors caught by the controller.
class InvoicesController; def rescue_action(e) raise e end; end

class InvoicesControllerTest < Test::Unit::TestCase
  def setup
    @controller = InvoicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @invoice = invoices(:johns_invoice)
  end

  context "An anonymous user" do
    should "not GET /admin/invoices" do
      get :index
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    should "not GET /admin/invoices/new" do
      get :new
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    should "not GET /admin/invoices/__ID__/edit" do
      get :edit, :id => @invoice.id
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    should "not POST /admin/invoices" do
      post :create, :invoice => {}
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    should "not PUT /admin/invoices/__ID__" do
      put :update, :id => @invoice.id, :invoice => {}
      assert_response :redirect
      assert_redirected_to new_session_path
    end
  end

  context "An authenticated user" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    context "without the :edit_invoices permission" do
      should "not GET /admin/invoices" do
        get :index
        assert_response :unauthorized
      end

      should "not GET /admin/invoices/new" do
        get :new
        assert_response :unauthorized
      end

      should "not GET /admin/invoices/__ID__/edit" do
        get :edit, :id => @invoice.id
        assert_response :unauthorized
      end

      should "not POST /admin/invoices" do
        post :create, :invoice => {}
        assert_response :unauthorized
      end

      should "not PUT /admin/invoices/__ID__" do
        put :update, :id => @invoice.id, :invoice => {}
        assert_response :unauthorized
      end
    end

    context "with the :edit_invoices permission" do
      setup do
        @bob.append_permissions(:edit_invoices)
      end

      context "GET /admin/invoices" do
        setup do
          get :index
        end

        should "have a successful response" do
          assert_response :success
        end

        should "assign to :invoices" do
          assert_not_nil assigns(:invoices)
        end

        should "render the index template" do
          assert_template "index"
        end
      end

      context "GET /admin/invoices/new" do
        setup do
          get :new
        end

        should "have a successful response" do
          assert_response :success
        end

        should "assign to :invoices" do
          assert_not_nil assigns(:invoice)
        end

        should "be a new record" do
          assert assigns(:invoice).new_record?
        end

        should "render the new template" do
          assert_template "new"
        end
      end

      context "GET /admin/invoices/__ID__/edit" do
        setup do
          get :edit, :id => @invoice.id
        end

        should "have a successful response" do
          assert_response :success
        end

        should "assign to :invoices" do
          assert_not_nil assigns(:invoice)
        end

        should "be the selected record" do
          assert_equal @invoice, assigns(:invoice)
        end

        should "render the edit view" do
          assert_template "edit"
        end
      end

      context "POST /admin/invoices" do
        setup do
          post :create, :invoice => params_for_invoice
        end

        should "instantiate a new invoice" do
          deny assigns(:invoice).new_record?
        end

        should "render the create template" do
          assert_template "create"
        end
      end

      context "PUT /admin/invoices/__ID__" do
        setup do
          put :update, :id => @invoice.id, :invoice => {}
        end

        should "update the existing record" do
          assert_include @invoice.reload.updated_at, (2.seconds.ago .. Time.now)
        end

        should "render the update template" do
          assert_template "update"
        end
      end
    end
  end
end
