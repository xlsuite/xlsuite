require File.dirname(__FILE__) + "/../spec_helper"

describe PostsController, "#show with an anonymous user" do
  it_should_behave_like "All controllers"

  before do
    @controller.stub!(:current_user?).and_return(false)
    @controller.stub!(:current_user).and_return(@user = mock("mock user"))

    @controller.stub!(:current_account).and_return(@account = mock_account)
    @forum_category = mock_forum_category
    @forum = mock_forum(:readable_by? => true)
    @topic = mock_topic
    @post = mock_post(:forum => @forum)

    @account.stub!(:forum_categories).and_return(collection_proxy(@forum_category, :find => @forum_category))
    @forum_category.stub!(:forums).and_return(collection_proxy(:find => @forum))
    @forum.stub!(:topics).and_return(collection_proxy(:find => @topic))
    @topic.stub!(:posts).and_return(collection_proxy(:find => @post))
  end

  def do_get
    get :show, :forum_category_id => @forum_category.id, :forum_id => @forum.id, :topic_id => @topic.id, :id => @post.id
  end

  it "should make the post available to the view" do
    do_get
    assigns[:post].should_not be_nil
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should render the posts/show template" do
    do_get
    response.should render_template("posts/show")
  end
end
