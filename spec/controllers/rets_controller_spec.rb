require File.dirname(__FILE__) + '/../spec_helper'

describe RetsController, "#index" do
  it_should_behave_like "All controllers"

  it "should NOT be accessible to anonymous users" do
    get :index
    response.should be_redirect
    response.should redirect_to(new_session_path)
  end

  it "should NOT be accessible to authenticated users" do
    @controller.stub!(:current_user?).and_return(true)
    @controller.stub!(:current_user).and_return(@user = mock_party)
    @user.should_receive(:can?).with(:access_rets).at_least(:once).and_return(false)

    get :index
    response.should be_redirect
    response.should redirect_to(new_session_path)
  end
end

describe RetsController, "#index with an authenticated and authorized user" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.should_receive(:can?).with(:access_rets).at_least(:once).and_return(true)
  end

  it "should be successful" do
    get :index
    response.should be_success
  end

  it "should render 'rets/index'" do
    get :index
    response.should render_template("rets/index")
  end
end

describe RetsController, "#search" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.should_receive(:can?).with(:access_rets).at_least(:once).and_return(true)

    RetsMetadata.stub!(:find_all_resources).and_return([])
  end

  it "should be successful" do
    get :search
    response.should be_success
  end

  it "should render the rets/search view" do
    get :search
    response.should render_template("rets/search")
  end
end

describe RetsController, "#do_search" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.should_receive(:can?).with(:access_rets).at_least(:once).and_return(true)
  end

  it "should instantiate a RetsSearchFuture with the correct arguments" do
    RetsSearchFuture.should_receive(:new).with(:owner => @user,
        :args => {:search => {:resource => "Property", :class => "11", :limit => "3"},
            :lines => [{:field => "Listing Date", :operator => "greater", :from => "2007-06-01"}]},
        :result_url => "/admin/rets/_id_;results").and_return(@rets_search_future = mock_model(RetsSearchFuture))

    @account.should_receive(:futures).and_return(@futures = collection_proxy)
    @futures.should_receive(:<<).with(@rets_search_future)
    @rets_search_future.should_receive(:save).and_return(true)

    post :do_search, "search" => {"resource" => "Property", "class" => "11", "limit" => "3"},
        "line" => {"1" => {"field" => "Listing Date", "operator" => "greater", "from" => "2007-06-01"}}
    response.should redirect_to(future_path(@rets_search_future))
  end
end
