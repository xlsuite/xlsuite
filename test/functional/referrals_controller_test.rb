require File.dirname(__FILE__) + '/../test_helper'
require 'referrals_controller'

# Re-raise errors caught by the controller.
class ReferralsController; def rescue_action(e) raise e end; end

class ReferralsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ReferralsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
    @domain = @account.domains.first
    @request.host = @domain.name

    @bob = parties(:bob)
    @params = {}
  end

  def do_get(params=@params)
    get :new, params
    @referral = assigns(:referral)
  end

  context "GETting on \#new (as an authenticated user)" do
    setup do
      login!(:bob)
    end

    should "allow the user to select his E-Mail address from a drop down" do
      get :new, @params
      assert_select "#x_you select#from_email option[selected]", @bob.email_addresses.first.address
    end
  end

  context "GETting on \#new (as anonymous)" do
    should "prevent return_to from being in another domain" do
      @params[:return_to] = "http://some.sex.host/here"
      do_get
      assert_nil @referral.return_to
    end

    should "prevent referral_url from being in another domain" do
      @params[:referral_url] = "http://some.sex.host/here"
      do_get
      assert_nil @referral.return_to
    end

    should "allow an absolute return_to within the same account" do
      @params[:return_to] = "http://#{@domain.name}/here"
      do_get
      assert_equal "http://#{@domain.name}/here", @referral.return_to
    end

    should "allow an absolute referral_url within the same account" do
      @params[:referral_url] = "http://#{@domain.name}/here"
      do_get
      assert_equal "http://#{@domain.name}/here", @referral.referral_url
    end

    should "absolutize return_to" do
      @params[:return_to] = "/here"
      do_get
      assert_equal "http://#{@domain.name}/here", @referral.return_to
    end

    should "absolutize referral_url" do
      @params[:referral_url] = "/here"
      do_get
      assert_equal "http://#{@domain.name}/here", @referral.referral_url
    end
  end

  context "POSTing to \#create (as an authenticated user)" do
    setup do
      login!(:bob)
      @params = {
          :referral => {
              :from => {:name => @bob.name.first, :email => @bob.main_email.address},
              :friends => [{:name => "John", :email => "john@xlsuite.com"}],
              :referral_url => "/listings/132",
              :return_to => "/thanks-for-the-referral",
              :reference => listings(:bobs_listing).dom_id}}
    end

    should "create a new contact route if the sender address is unknown" do
      @params[:referral][:from][:email] = "some-new-address@xlsuite.com"
      post :create, @params
      assert @bob.email_addresses(true).any? {|a| a.address == "some-new-address@xlsuite.com"},
          "The new address wasn't added to Bob's user: #{@bob.email_addresses.map(&:address)}"
    end
  end

  context "POSTing to \#create (as anonymous)" do
    setup do
      @params = {
          :referral => {
              :from => {:name => @bob.name.first, :email => @bob.main_email.address},
              :friends => [{:name => "John", :email => "john@xlsuite.com"}],
              :referral_url => "/listings/132",
              :return_to => "/thanks-for-the-referral",
              :reference => listings(:bobs_listing).dom_id}}
    end

    should "return to @params[:referral][:return_to]" do
      @params[:referral][:return_to] = "/my-listings"
      post :create, @params 
      assert_response :redirect
      assert_redirected_to "http://#{@domain.name}/my-listings"
    end

    should "return to the referral_url when no return_to" do
      @params[:referral].delete(:return_to)
      post :create, @params
      assert_response :redirect
      assert_redirected_to "http://#{@domain.name}/listings/132"
    end

    should "record the referral URL in the referral" do
      post :create, @params
      assert_equal "http://test.host/listings/132", assigns(:referral).reload.referral_url
    end

    should "record the reference in the referral" do
      post :create, @params
      assert_equal listings(:bobs_listing), assigns(:referral).reload.reference
    end

    should "map from to a Friend instance" do
      @referral = Referral.new
      Referral.expects(:new).with do |params|
        params[:from] == Friend.new(:name => @bob.name.first, :email => @bob.main_email.address)
      end.returns(@referral)
      post :create, @params
    end 

    should "map friends to Friend instances" do
      @referral = Referral.new
      Referral.expects(:new).with do |@params|
        @params[:friends] == [Friend.new(:name => "John", :email => "john@xlsuite.com")]
      end.returns(@referral)
      post :create, @params
    end

    should "release the generated mail" do
      post :create, @params
      assert assigns(:referral).reload.email.ready?
    end

    context "with an invalid sender" do
      setup do
        @from = @params[:referral][:from]
        @from[:name] = "Sammy the Attacker"
        @from[:email] = "sammy"
        post :create, @params
      end

      should "render the new action" do
        assert_template "new"
      end

      should "leave the sender's name in the from fields" do
        assert_select "#from_name[name=?][value=?]", "referral[from][name]", @from[:name]
        assert_select "#from_email[name=?][value=?]", "referral[from][email]", @from[:email]
      end
    end

    context "with an invalid recipient" do
      setup do
        @friend = {:email => "carla", :name => "Carla the Temptress"}
        @params[:referral][:friends] = []
        @params[:referral][:friends] << @friend 
        post :create, @params
      end

      should "render the new action" do
        assert_template "new"
      end

      should "leave the friend's name in the friends fields" do
        assert_select "input[name=?][value=?]", "referral[friends][][name]", @friend[:name]
        assert_select "input[name=?][value=?]", "referral[friends][][email]", @friend[:email]
      end
    end
  end
end
