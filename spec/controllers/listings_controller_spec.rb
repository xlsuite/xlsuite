require File.dirname(__FILE__) + "/../spec_helper.rb"

describe ListingsController, " with an anonymous user" do
  it_should_behave_like "All controllers"

  before do
    @listings = collection_proxy(:find => [], :tags => [])
    @account.stub!(:listings).and_return(@listings)
    @listing = mock_listing
  end

  it "should return a list of listings" do
    get :index

    assigns(:listings).should_not be_nil
    response.should be_success
    response.should render_template("listings/index")
  end

  it "should show an individual listing" do
    @listings.should_receive(:find).with(:first, :conditions => {:id => @listing.id.to_s}).and_return(@listing)
    get :show, :id => @listing.id

    assigns(:listing).should == @listing
    response.should be_success
    response.should render_template("listings/show")
  end

  it "should not allow viewing the new listing form" do
    @listings.should_not_receive(:build)
    get :new

    response.should redirect_to(new_session_path)
  end

  it "should not allow the creation of a listing" do
    post :create, :listing => {:bedrooms => 2, :public => true}

    response.should redirect_to(new_session_path)
  end

  it "should not allow editing an existing listing" do
    @listings.should_not_receive(:build)
    get :edit, :id => @listing.id

    response.should redirect_to(new_session_path)
  end

  it "should not allow updating an existing listing" do
    @listings.should_not_receive(:find)
    put :update, :id => @listing.id, :listing => {:bedrooms => 7}

    response.should redirect_to(new_session_path)
  end

  it "should not allow destroying an existing listing" do
    @listings.should_not_receive(:find)
    delete :destroy, :id => @listing.id

    response.should redirect_to(new_session_path)
  end

  it "should not allow importing listings" do
    get :import
    response.should redirect_to(new_session_path)
  end
end

describe ListingsController, " with an user with :edit_listings permission" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.stub!(:can?).and_return(true)
    @listings = collection_proxy(:find => [], :tags => [])
    @account.stub!(:listings).and_return(@listings)
    @listing = mock_listing
  end

  it "should allow viewing the new listing form" do
    @listings.should_receive(:build).and_return(@listing = mock_model(Listing))
    @listing.should_receive(:build_address).with(no_args).and_return(mock_model(AddressContactRoute))
    get :new

    response.should be_success
    response.should render_template("listings/new")
  end

  it "should allow the creation of a listing" do
    @listings.should_receive(:build).and_return(@listing = mock_model(Listing))
    @listing.should_receive(:build_address).and_return(@address = mock_model(AddressContactRoute))
    @listing.stub!(:address).and_return(@address)
    @listing.should_receive(:account=).with(@account)
    @listing.should_receive(:save!).and_return(true)

    @address.should_receive(:line1).and_return("line1")
    @address.should_receive(:account=).with(@account)
    @address.should_receive(:save!).and_return(true)

    post :create, :listing => {:bedrooms => 2, :public => true}

    response.should redirect_to(listings_path)
  end

  it "should allow editing an existing listing" do
    @listings.should_receive(:find).with(:first, :conditions => {:id => @listing.id.to_s}).and_return(@listing)
    @listing.should_receive(:build_address).with(no_args).and_return(mock_model(AddressContactRoute))
    @listing.should_receive(:address).with(no_args).and_return(nil)
    get :edit, :id => @listing.id

    response.should be_success
    response.should render_template("listings/edit")
  end

  it "should not create a new address if an existing one is found" do
    @listings.should_receive(:find).with(:first, :conditions => {:id => @listing.id.to_s}).and_return(@listing)
    @listing.should_receive(:address).with(no_args).and_return(mock_address)
    get :edit, :id => @listing.id

    response.should be_success
    response.should render_template("listings/edit")
  end

  it "should allow updating an existing listing" do
    @listings.should_receive(:find).with(:first, :conditions => {:id => @listing.id.to_s}).and_return(@listing)
    @listing.should_receive(:address).and_return(@address = mock_address)
    @listing.should_receive(:update_attributes!).with("bedrooms" => "7",
        "account" => @account, "price" => Money.zero, "rent" => Money.zero).and_return(true)
    @address.should_receive(:update_attributes!).with(:account => @account).and_return(true)

    put :update, :id => @listing.id, :listing => {:bedrooms => "7"}

    response.should redirect_to(listings_path)
  end

  it "should allow destroying an existing listing" do
    @listings.should_receive(:find).with(:first, :conditions => {:id => @listing.id.to_s}).and_return(@listing)
    @listing.should_receive(:destroy).and_return(true)
    delete :destroy, :id => @listing.id

    response.should redirect_to(listings_path)
  end

  it "should allow importing listings" do
    @listings.should_receive(:find).with(:first, :conditions => {:mls_no => "a93"}).and_return(@listing)
    @listing.should_receive(:publicify!).and_return(true)

    post :import, :mls_no => "a93"

    response.should be_redirect
    response.should redirect_to(edit_listing_path(@listing))
  end
end
