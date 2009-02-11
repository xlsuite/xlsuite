require File.dirname(__FILE__) + "/../spec_helper.rb"

describe ForumCategoriesController, "#index with an anonymous user" do
  it_should_behave_like "All controllers"

  before do
    @forum_categories = collection_proxy(:find => [], :build => mock_model(ForumCategory))
    @account.stub!(:forum_categories).and_return(@forum_categories)

    @controller.stub!(:render_within_public_layout)
  end

  def do_get
    get :index
  end

  it "should make an array of forum categories available for the view" do
    do_get
    assigns[:forum_categories].should_not be_nil
  end

  it "should get the forum categories from the current account" do
    do_get
  end

  it "should render within the public layout" do
    @controller.should_receive(:render_within_public_layout)
    do_get
  end

  it "should render be successful" do
    do_get
    response.should be_success
  end

  it "should render the index template" do
    do_get
    response.should render_template("forum_categories/index")
  end
end

describe ForumCategoriesController, "#index with an authenticated user" do
  it_should_behave_like "All authenticated controllers"

  before do
    @forum_categories = collection_proxy(:find => [], :build => mock_model(ForumCategory))
    @account.stub!(:forum_categories).and_return(@forum_categories)

    @controller.stub!(:render_within_public_layout)
  end

  def do_get
    get :index
  end

  it "should make an array of forum categories available for the view" do
    do_get
    assigns[:forum_categories].should_not be_nil
  end

  it "should render within the public layout" do
    @controller.should_receive(:render_within_public_layout)
    do_get
  end

  it "should render be successful" do
    do_get
    response.should be_success
  end

  it "should render the index template" do
    do_get
    response.should render_template("forum_categories/index")
  end
end

describe ForumCategoriesController, "#index with an authenticated user part of the 'Access' group" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.stub!(:member_of?).and_return(true)

    @forum_categories = collection_proxy(:find => [], :build => mock_model(ForumCategory))
    @account.stub!(:forum_categories).and_return(@forum_categories)

    @controller.stub!(:render_within_public_layout)
  end

  def do_get
    get :index
  end

  it "should make an array of forum categories available for the view" do
    do_get
    assigns[:forum_categories].should_not be_nil
  end

  it "should render within the public layout" do
    @user.should_receive(:member_of?).with("Access").and_return(true)
    @controller.should_not_receive(:render_within_public_layout)
    do_get
  end

  it "should render be successful" do
    do_get
    response.should be_success
  end

  it "should render the index template" do
    do_get
    response.should render_template("forum_categories/index")
  end
end

describe ForumCategoriesController, "#new with an authenticated admin" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.should_receive(:can?).with(:admin_forum).at_least(1).and_return(true)

    @forum_categories = collection_proxy(:find => [], :build => mock_model(ForumCategory))
    @account.stub!(:forum_categories).and_return(@forum_categories)

    @controller.stub!(:render_within_public_layout)
  end

  def do_get
    get :new
  end

  it "should make a new forum category available for use" do
    do_get
    assigns[:forum_category].should_not be_nil
  end

  it "should use the current account to build the forum category" do
    @account = mock_account(
        :forum_categories => collection_proxy(:build => mock_forum_category))
    @controller.should_receive(:current_account).at_least(1).and_return(@account)
    @controller.should_receive(:render_within_public_layout)
    do_get
  end

  it "should render the forum_categories/new view" do
    do_get
    response.should render_template("forum_categories/new")
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
end

describe ForumCategoriesController, "#new with an anonymous user" do
  it_should_behave_like "All controllers"

  def do_get
    get :new
  end

  it "should redirect to the login url" do
    do_get
    response.should redirect_to(new_session_path)
  end
end
