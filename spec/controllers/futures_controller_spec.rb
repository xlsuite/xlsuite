require File.dirname(__FILE__) + '/../spec_helper'

describe FuturesController, "#show with an anonymous user" do
  it_should_behave_like "All controllers"

  it "should redirect to /sessions/new" do
    get :show, :id => 128
    response.should redirect_to(new_session_path)
  end
end

describe FuturesController, "#show with an authenticated user" do
  it_should_behave_like "All authenticated controllers"

  before do
    @future = mock_future(:completed? => false)
    Future.stub!(:find_by_account_id_and_owner_id_and_id).and_return(@future)
  end

  it "should show only this user's futures" do
    Future.should_receive(:find_by_account_id_and_owner_id_and_id).with(@account, @user, "147").and_return(@future)
    get :show, :id => 147
    assigns(:future).should == @future
    response.should render_template("show")
  end

  it "should redirect to the #return_to if the future is completed" do
    @future.should_receive(:completed?).at_least(:once).and_return(true)
    @future.should_receive(:return_to).at_least(:once).and_return("/some-result-url")
    get :show, :id => 131
    response.should redirect_to("/some-result-url")
  end

  it "should render the RJS template when called using an xhr request" do
    xhr :get, :show, :id => 121
    response.should render_template("show.rjs")
  end

  it "should NOT redirect to the result_url if the future is completed and called using XHR" do
    @future.stub!(:completed?).and_return(true)
    @future.stub!(:return_to).and_return("/some-result-url")
    xhr :get, :show, :id => 121
    response.should render_template("show.rjs")
  end
end

describe FuturesController, "#show with an authenticated user and control parameters" do
  it_should_behave_like "All authenticated controllers"

  before do
    @future = mock_future(:completed? => false)
    Future.stub!(:find_by_account_id_and_owner_id_and_id).and_return(@future)
  end

  it "should set @status to 'status' when no status parameter sent" do
    get :show, :id => @future.id
    assigns(:status).should == "status"
  end

  it "should set @status to nil when status parameter present but empty" do
    get :show, :id => @future.id, :status => ""
    assigns(:status).should be_nil
  end

  it "should set @status to 'property_1231_status' when status parameter present and set to 'property_1231_status'" do
    get :show, :id => @future.id, :status => "property_1231_status"
    assigns(:status).should == "property_1231_status"
  end

  it "should set @progress to 'progress' when no progress parameter sent" do
    get :show, :id => @future.id
    assigns(:progress).should == "progress"
  end

  it "should set @progress to nil when progress parameter present but empty" do
    get :show, :id => @future.id, :progress => ""
    assigns(:progress).should be_nil
  end

  it "should set @progress to 'property_1231_progress' when progress parameter present and set to 'property_1231_progress'" do
    get :show, :id => @future.id, :progress => "property_1231_progress"
    assigns(:progress).should == "property_1231_progress"
  end

  it "should set @elapsed to 'elapsed' when no elapsed parameter sent" do
    get :show, :id => @future.id
    assigns(:elapsed).should == "elapsed"
  end

  it "should set @elapsed to nil when elapsed parameter present but empty" do
    get :show, :id => @future.id, :elapsed => ""
    assigns(:elapsed).should be_nil
  end

  it "should set @elapsed to 'property_1231_elapsed' when elapsed parameter present and set to 'property_1231_elapsed'" do
    get :show, :id => @future.id, :elapsed => "property_1231_elapsed"
    assigns(:elapsed).should == "property_1231_elapsed"
  end
end

describe FuturesController, "#show with an authenticated user, control parameters and XHR" do
  it_should_behave_like "All authenticated controllers"
  integrate_views

  before do
    @future = mock_future(:completed? => false, :progress => 47, :status => "in_progress",
        :return_to => nil, :started_at => 8.seconds.ago)
    Future.stub!(:find_by_account_id_and_owner_id_and_id).and_return(@future)
  end

  it "should update the 'progress' element when no progress parameter" do
    xhr :get, :show, :id => @future.id
    response.should have_rjs(:replace_html, "progress")
  end

  it "should update the 'property_3213_progress' element when a progress parameter with value 'property_3213_progress' is present" do
    xhr :get, :show, :id => @future.id, :progress => "property_3213_progress"
    response.should have_rjs(:replace_html, "property_3213_progress")
  end

  it "should not update the 'progress' element when a progress parameter is sent but empty" do
    xhr :get, :show, :id => @future.id, :progress => ""
    response.should_not have_rjs(:replace_html, "progress")
  end

  it "should update the 'status' element when no status parameter" do
    xhr :get, :show, :id => @future.id
    response.should have_rjs(:replace_html, "status")
  end

  it "should update the 'property_3213_status' element when a status parameter with value 'property_3213_status' is present" do
    xhr :get, :show, :id => @future.id, :status => "property_3213_status"
    response.should have_rjs(:replace_html, "property_3213_status")
  end

  it "should not update the 'status' element when a status parameter is sent but empty" do
    xhr :get, :show, :id => @future.id, :status => ""
    response.should_not have_rjs(:replace_html, "status")
  end

  it "should update the 'elapsed' element when no elapsed parameter" do
    xhr :get, :show, :id => @future.id
    response.should have_rjs(:replace_html, "elapsed")
  end

  it "should update the 'property_3213_elapsed' element when a elapsed parameter with value 'property_3213_elapsed' is present" do
    xhr :get, :show, :id => @future.id, :elapsed => "property_3213_elapsed"
    response.should have_rjs(:replace_html, "property_3213_elapsed")
  end

  it "should not update the 'elapsed' element when a elapsed parameter is sent but empty" do
    xhr :get, :show, :id => @future.id, :elapsed => ""
    response.should_not have_rjs(:replace_html, "elapsed")
  end
end
