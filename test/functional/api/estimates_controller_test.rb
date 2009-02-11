require File.dirname(__FILE__) + '/../../test_helper'
require 'api/estimates_controller'

# Re-raise errors caught by the controller.
class Api::EstimatesController; def rescue_action(e) raise e end; end

class Api::EstimatesControllerTest < Test::Unit::TestCase
  def setup
    @controller = Api::EstimatesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = accounts(:wpul)
  end

  context "An existing, blank, estimate" do
    setup do
      @estimate = @account.estimates.create!(:date => Date.today, :invoice_to => parties(:bob), :apply_pst_on_labor => false)
    end

    context "with an Authorization header" do
      setup do
        @key = parties(:bob).grant_api_access!
        @authz_header = "Basic " + Base64.encode64("bob:#{@key}")
        @request.env["HTTP_AUTHORIZATION"] = @authz_header.chomp
      end

      should "create a new estimate when the UUID cannot be found" do
        assert_difference Estimate, :count, 1 do
          post :create, :estimate => {:uuid => @estimate.uuid.succ, :date => Date.today.to_s(:db), :invoice_to => {:email => parties(:bob).main_email.address}}
          assert_response :success, @response.body
        end
      end

      should "update the apply_pst_on_labor column" do
        post :create, :estimate => {:uuid => @estimate.uuid, :date => Date.today.to_s(:db), :apply_pst_on_labor => "1", :invoice_to => {:email => parties(:bob).main_email.address}}
        assert_response :success, @response.body
        assert @estimate.reload.apply_pst_on_labor?
      end
    end
  end

  context "Creating an estimate through the API" do
    context "without an Authorization header" do
      setup do
        post :create, :estimate => {}
      end

      should "respond with 401 Unauthorized" do
        assert_response 401
      end

      should "return a WWW-Authenticate response header" do
        assert_not_nil @response.headers["WWW-Authenticate"]
      end
    end

    context "with an authorized API user" do
      setup do
        @key = parties(:bob).grant_api_access!
        @authz_header = "Basic " + Base64.encode64("bob:#{@key}")
        @request.env["HTTP_AUTHORIZATION"] = @authz_header.chomp
      end

      context "with :edit_estimate permission" do
        setup do
          parties(:bob).append_permissions(:edit_estimate)
          post :create, :estimate => {:transport_fee => "50 usd", :invoice_to => {:email => "doggy@test.com"}, :date => Time.now.utc}
          @estimate = assigns(:estimate)
        end

        should "assign to @estimate" do
          assert_kind_of Estimate, @estimate
        end

        should "correctly set the transport_fee" do
          assert_equal "50 usd".to_money, @estimate.transport_fee
        end

        should "respond with a 201 Created" do
          assert_response 201
        end

        should "set the response's Location header to the estimate's URL" do
          assert_equal api_estimate_url(@estimate), @response.headers["Location"]
        end
        
        context "containing line items" do
          setup do
            parties(:bob).append_permissions(:edit_estimate)
            @product_count = Product.count
            post :create, :estimate => {
              :transport_fee => "50 usd", :invoice_to => {:email => "doggy@test.com"}, :date => Time.now.utc,
              :lines => [
                  {:quantity => 1, :retail_price => "999 usd", :name => "my rabbit", :model => "RABBIT00", :description => "Super duper white rabbit", :sku => "RABBIT00_SKU"},
                  {:quantity => 1, :retail_price => "10 usd", :name => "brown dog", :model => "DOGGY00", :description => "Nice one eh", :sku => "DOGGY00_SKU"}
                ]
              }
            @estimate = assigns(:estimate)
          end
          
          should "create the products automatically" do
            logger.warn("^^^im about to do a count here #{Product.count}")
            logger.warn("^^^im about to do a count here #{Product.count}")
            logger.warn("^^^product count here #{@product_count}")
            logger.warn("^^^estimate lines count here #{@estimate.lines.count}")
            logger.warn("^^^estimate lines count here #{@estimate.lines.count}")
            assert_equal @product_count + @estimate.lines.count, Product.count
          end
          
          should "assign the product to the estimate lines" do
            @estimate.lines.each do |line|
              puts line.product.inspect
              assert_not_nil line.product
            end
          end
        end
      end

      context "with formatted responses" do
        setup do
          parties(:bob).append_permissions(:edit_estimate)
        end

        should "respond with 406 Not Acceptable when requesting a JSON response" do
          post :create, :estimate => {}, :format => :json
          assert_response 406
        end

        should "respond with 406 Not Acceptable when requesting a javascript response" do
          post :create, :estimate => {}, :format => :js
          assert_response 406
        end

        should "respond with 406 Not Acceptable when requesting an HTML response" do
          post :create, :estimate => {}, :format => :html
          assert_response 406
        end
      end

      context "without the :edit_estimate permission" do
        setup do
          parties(:bob).permission_grants.delete_all
          post :create, :estimate => {:transport_fee => "50 usd"}
        end

        should "respond with a 403 Forbidden" do
          assert_response 403
        end
      end
    end
  end
end
