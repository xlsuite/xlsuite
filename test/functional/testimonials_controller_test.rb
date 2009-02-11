require File.dirname(__FILE__) + '/../test_helper'
require 'testimonials_controller'

# Re-raise errors caught by the controller.
class TestimonialsController; def rescue_action(e) raise e end; end

module TestimonialsControllerTest
  class UnauthenticatedTestimonialAccess < Test::Unit::TestCase
    def setup
      @controller = TestimonialsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @bob = parties(:bob)
      @account = @bob.account
      @testimonial = @bob.testimonials.create!(:body => "me")
      @proxy = Object.new
    end

    def test_can_get_new
      get :new
      assert_response :success
      assert_template "new"
    end

    def test_cannot_use_email_address_from_other_account
      @account0 = Account.new; @account0.expires_at = 5.minutes.from_now; @account0.save!
      @party0 = @account0.parties.create!
      @email0 = @party0.main_email
      @email0.update_attribute(:address, "single@nowhere.com")

      assert_difference Party, :count, 1 do
        assert_difference EmailContactRoute, :count, 1 do
          assert_difference Testimonial, :count, 1 do
            post :create,
                :testimonial => {:body => "a major snowstorm..."},
                :party => {:first_name => "John", :last_name => "Batelle"},
                :email => {:address => "single@nowhere.com"}
          end
        end
      end

      assert_equal [], @party0.reload.testimonials,
          "Testimonial was assigned to existing party from another account"
    end

    def test_can_create_party_email_and_testimonial
      assert_difference Party, :count, 1 do
        assert_difference EmailContactRoute, :count, 1 do
          assert_difference Testimonial, :count, 1 do
            post :create,
                :testimonial => {:body => "a major snowstorm..."},
                :party => {:first_name => "John", :last_name => "Batelle"},
                :email => {:address => "john@batelle.org"}
          end
        end
      end

      assert_response :redirect
      assert_redirected_to testimonials_path

      assert_not_nil assigns(:party), "No :party assign"
      assert_equal @account, assigns(:party).account, "Correct account wasn't assigned to created party"
      assert_equal "John", assigns(:party).first_name
      assert_equal "Batelle", assigns(:party).last_name

      assert_not_nil assigns(:email), "No :email assign"
      assert_equal @account, assigns(:email).account, "Correct account wasn't assigned to created e-mail address"
      assert_equal [assigns(:email)], assigns(:party).contact_routes(true),
          "EmailContactRoute does not reference parent party"
      assert_equal "john@batelle.org", assigns(:email).address

      assert_not_nil assigns(:testimonial), "No :testimonial assign"
      assert_equal @account, assigns(:testimonial).reload.account,
          "Correct account wasn't assigned to created testimonial"
      assert_equal assigns(:party), assigns(:testimonial).reload.party,
          "John's testimonial should have been assigned to him"
      assert_equal "a major snowstorm...", assigns(:testimonial).body
      assert_equal Date.today, assigns(:testimonial).testified_on
      assert_nil assigns(:testimonial).approved_at,
          "Anonymous testimonials must NOT be approved by default"
    end

    def test_can_create_against_existing_party
      @party = @account.parties.create!
      @email = @party.email_addresses.create!(:address => "billy@bob.com")
      post :create,
          :testimonial => {:body => "snowstorm"},
          :party => {}, :email => {:address => @email.address}

      assert_response :redirect
      assert_redirected_to testimonials_path

      @party.reload
      assert_equal @party, assigns(:testimonial).reload.party,
          "Billy's testimonial should have been assigned to him"
      assert_nil assigns(:testimonial).approved_at,
          "Anonymous testimonials must NOT be approved by default"
    end

    def test_create_rejected_when_no_email_address
      post :create,
          :testimonial => {:body => "snowstorm"}

      assert_template "testimonials/new"
    end

    def test_create_rejected_when_blank_email_address
      post :create,
          :testimonial => {:body => "snowstorm"},
          :email => {:address => ""}

      assert_template "testimonials/new"
    end

    def test_can_create_with_javascript_format
      post :create,
          :testimonial => {:body => "a major snowstorm..."},
          :party => {:first_name => "John", :last_name => "Batelle"},
          :email => {:address => "john@batelle.org"},
          :format => "js"

      assert_response :success
      assert_template "testimonials/create.rjs"
    end

    def test_cannot_index_anything_besides_approved_testimonials
      @proxy.expects(:find).with {|*args| args.first == :all}.returns([])
      @proxy.stubs(:count).returns(0)
      Testimonial.expects(:approved).at_least_once.returns(@proxy)
      get :index, :filter => "unapproved"

      assert_response :success
      assert_template "testimonials/index"
    end

    def test_can_view_index
      @proxy.expects(:find).with {|*args| args.first == :all}.returns([])
      @proxy.stubs(:count).returns(0)
      Testimonial.expects(:approved).at_least_once.returns(@proxy)
      get :index

      assert_response :success
      assert_template "testimonials/index"
    end

    def test_can_show_testimonial
      @proxy.expects(:find).with(@testimonial.id.to_s).returns(@testimonial)
      Testimonial.expects(:approved).returns(@proxy)
      get :show, :id => @testimonial.id

      assert_response :success
      assert_template "testimonials/show"
    end

    def test_cannot_show_unapproved_testimonial
      @proxy.expects(:find).raises(ActiveRecord::RecordNotFound)
      Testimonial.expects(:approved).returns(@proxy)
      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, :id => @testimonial.id
      end
    end

    def test_cannot_edit_testimonial
      get :edit, :id => @testimonial.id
      assert_redirected_to new_session_path
    end

    def test_cannot_update_testimonial
      original_body = @testimonial.body
      put :update, :id => @testimonial.id, :testimonial => {:body => "a new body"}

      assert_redirected_to new_session_path
      assert_equal original_body, Testimonial.find(@testimonial.id).body
    end

    def test_cannot_destroy_testimonial
      delete :destroy, :id => @testimonial.id

      assert_redirected_to new_session_path
      assert_nothing_raised { Testimonial.find(@testimonial.id) }
    end
  end

  class AuthenticatedUserWithEditPartyPermissionTestimonialAccess < Test::Unit::TestCase
    def setup
      @controller = TestimonialsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @bob = login_with_permissions!(:bob, :edit_party)
      @testimonial = @bob.testimonials.create!(:body => "me")
      @proxy = Object.new
    end

    def test_can_view_index
      Testimonial.stubs(:find).returns([])
      get :index
      assert_not_nil assigns(:testimonials)
    end

    def test_can_view_unapproved_testimonials
      @proxy.expects(:find).returns(testimonials = [])
      @proxy.stubs(:count).returns(0)
      Testimonial.stubs(:unapproved).returns(@proxy)
      get :index, :filter => "Unapproved"

      assert_equal testimonials, assigns(:testimonials)
    end

    def test_can_view_rejected_testimonials
      @proxy.expects(:find).returns(testimonials = [])
      @proxy.stubs(:count).returns(0)
      Testimonial.expects(:rejected).at_least_once.returns(@proxy)
      get :index, :filter => "Rejected"

      assert_equal testimonials, assigns(:testimonials)
    end

    def test_can_view_all_testimonials
      @proxy.expects(:find).returns(testimonials = [])
      @proxy.stubs(:count).returns(0)
      Testimonial.expects(:all).at_least_once.returns(@proxy)
      get :index, :filter => "All"

      assert_equal testimonials, assigns(:testimonials)
    end

    def test_can_show_individual_testimonial
      get :show, :id => @testimonial.id
      assert_response :success
      assert_template "testimonials/show"
    end

    def test_can_get_new
      get :new
      assert_response :success
      assert_template "testimonials/new"
    end

    def test_can_create_against_existing_party
      assert_difference Party, :count, 0 do
        assert_difference EmailContactRoute, :count, 0 do
          assert_difference Testimonial, :count, 1 do
            post :create, :party_id => @bob.id,
                :testimonial => {:body => "a major snowstorm..."},
                :format => "js"
          end
        end
      end

      assert_response :success
      assert_template "testimonials/create.rjs"

      assert_equal @bob, assigns(:party)

      assert_not_nil assigns(:testimonial), "No :testimonial assign"
      assert_equal "a major snowstorm...", assigns(:testimonial).body
      assert_equal Date.today, assigns(:testimonial).testified_on
    end

    def test_can_approve_existing_testimonial
      Testimonial.expects(:find).with {|*args| args.first == @testimonial.id.to_s}.returns(@testimonial)
      @testimonial.expects(:approve!).returns(true)
      put :approve, :id => @testimonial.id
      assert_response :redirect
      assert_redirected_to testimonial_path(@testimonial)
    end

    def test_can_reject_existing_testimonial
      Testimonial.expects(:find).with {|*args| args.first == @testimonial.id.to_s}.returns(@testimonial)
      @testimonial.expects(:reject!).returns(true)
      put :reject, :id => @testimonial.id
      assert_response :redirect
      assert_redirected_to testimonial_path(@testimonial)
    end
  end
end
