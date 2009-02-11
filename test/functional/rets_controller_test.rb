require File.dirname(__FILE__) + "/../test_helper"
require 'rets_controller'

# Re-raise errors caught by the controller.
class RetsController; def rescue_action(e) raise e end; end

class RetsControllerTest < Test::Unit::TestCase
  def setup
    @controller = RetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account    = accounts(:wpul)
  end

  context "An account" do
    setup do
      @account = accounts(:wpul)
    end

    context "whose RETS option is false" do
      setup do
        @account.options.rets = false
        @account.save!
      end

      context "with an anonymous visitor" do
        context "on GET /admin/rets/listings_search" do
          setup do
            get :listings_search
          end

          should_respond_with :missing
        end
      end

      context "with an authenticated visitor with no permissions" do
        setup do
          login_with_no_permissions!(:bob)
        end

        context "on GET /admin/rets/listings_search" do
          setup do
            get :listings_search
          end

          should_respond_with :missing
        end
      end

      context "with an authenticated visitor that has the :access_rets permission" do
        setup do
          login_with_permissions!(:bob, :access_rets)
        end

        context "on GET /admin/rets/listings_search" do
          setup do
            get :listings_search
          end

          should_respond_with :missing
        end
      end
    end

    context "whose RETS option is true" do
      setup do
        @account.options.rets = true
        @account.save!
      end

      context "with an anonymous visitor" do
        context "on GET /admin/rets/listings_search" do
          setup do
            get :listings_search
          end

          should_respond_with :missing
        end
      end

      context "with an authenticated user that has no permissions" do
        setup do
          login_with_no_permissions!(:bob)
        end

        context "on GET /admin/rets/listings_search" do
          setup do
            get :listings_search
          end

          should_respond_with :missing
        end
      end

      context "with an authenticated user that has :access_rets permission" do
        setup do
          login_with_permissions!(:bob, :access_rets)
        end

        context "POSTing to /admin/rets/do_listings_search.js with a repeat interval" do
          setup do
            post :do_listings_search, :search => {:repeat_interval => "4h", :resource => "Property", :class => "1"}, :line => {"1" => {:field => "1211", :operator => "eq", :from => "V255447"}}, :format => "js"
          end

          should_respond_with :success
          should_render_template "do_listings_search"
          should_change "accounts(:wpul).futures.count", :by => 1

          should "set the interval on the future" do
            assert_equal Period.new(4, "hours").as_seconds, accounts(:wpul).futures.last.interval
          end
        end

        context "on GET /admin/rets/listings_search" do
          setup do
            get :listings_search
          end

          should_respond_with :success
          should_render_template "listings_search"
        end
      end
    end
  end

  should_route :post, "/admin/rets/do_listings_search.js", :controller => "rets", :action => "do_listings_search", :format => "js"
  should_route :post, "/admin/rets/do_listings_search", :controller => "rets", :action => "do_listings_search"
end
