require File.dirname(__FILE__) + "/../../spec_helper.rb"

describe "Any forum categories", :shared => true do
  before(:each) do
    @forum_category = mock_model(ForumCategory, :name => "forum category",
        :dom_id => "forum_category_X", :description => "some description",
        :created_at => 5.days.ago)
    @forum = mock_model(Forum, :forum_category => @forum_category,
        :name => "forum", :dom_id => "forum_X",
        :description => "some description for the forum",
        :topics_count => 1, :posts_count => 1)
    @topic = mock_model(ForumTopic, :title => "topic title",
        :sticky? => false, :forum => @forum,
        :forum_category => @forum_category,
        :posts_count => 1)
    @post = mock_model(ForumPost, :created_at => 2.hours.ago,
        :topic => @topic, :forum => @forum,
        :forum_category => @forum_category,
        :body => "this is the body")
    @user = mock_model(Party, :display_name => "Me")

    @forum_category.stub!(:forums).and_return([@forum])
    @forum_category.stub!(:topics).and_return([@topic])
    @forum_category.topics.stub!(:count).and_return(1)
    @forum_category.stub!(:posts).and_return([@post])
    @forum_category.forums.stub!(:readable_by).and_return([@forum])
    @forum_category.posts.stub!(:count).and_return(1)
    @forum.stub!(:topics).and_return([@topic])
    @forum.topics.stub!(:find).and_return([@topic])
    @forum.stub!(:posts).and_return([@post])
    @topic.stub!(:posts).and_return([@post])
    @post.stub!(:user).and_return(@user)

    @topic.stub!(:editable_by?).and_return(true)

    @forum.stub!(:readable_by?).and_return(true)
    @forum.stub!(:writeable_by?).and_return(true)

    assigns[:forum_categories] = [@forum_category]
  end
end

describe "forum_categories/index (anonymous user)" do
  it_should_behave_like "Any forum categories"

  before do
    @controller.template.stub!(:current_user?).and_return(false)
    @controller.template.stub!(:current_user).and_return(@user = mock("mock user"))
    @user.stub!(:can?).and_return(false)
  end

  it "should only render forums accessible to anonymous users" do
    @forum_category.forums.should_receive(:readable_by).with(nil).and_return([])
    do_render
  end

  it "should not render a link to add a new category" do
    do_render
    response.should_not have_tag("a[href$=?]", :text => /Add New Category/i)
  end

  it "should not render a link to add a new forum" do
    do_render
    response.should_not have_tag("a[href$=?]", :text => /Add New Forum/i)
  end

  it "should not render a link to add a new topic" do
    do_render
    response.should_not have_tag("a[href$=?]", :text => /Add New Topic/i)
  end

  it "should not render a link to add a new post" do
    do_render
    response.should_not have_tag("a[href$=?]", :text => /Reply/i)
  end

  def do_render
    render "forum_categories/index"
  end
end

describe "forum_categories/index (logged-in user, non-admin, no write restrictions)" do
  it_should_behave_like "Any forum categories"

  before do
    @controller.template.stub!(:current_user?).and_return(true)
    @controller.template.stub!(:current_user).and_return(@user = mock("mock user"))
    @user.stub!(:can?).and_return(false)
  end

  it "should render forums accessible to the logged-in user" do
    @forum_category.forums.should_receive(:readable_by).with(@user).and_return([])
    do_render
  end

  it "should not render a link to add a new category" do
    do_render
    response.should_not have_tag("a[href$=?]", new_forum_category_path, :text => /Add New Category/i)
  end

  it "should not render a link to add a new forum" do
    do_render
    response.should_not have_tag("a[href$=?]", new_forum_path(@forum_category), :text => /Add New Forum/i)
  end

  it "should render a link to add a new topic" do
    do_render
    response.should have_tag("a[href$=?]", new_topic_path(@forum_category, @forum), :text => /Add New Topic/i)
  end

  it "should render a link to add a new post" do
    do_render
    response.should have_tag("a[href$=?]", new_post_path(@forum_category, @forum, @topic), :text => /Reply/i)
  end

  def do_render
    render "forum_categories/index"
  end
end

describe "forum_categories/index (logged-in user, admin, no write restrictions)" do
  it_should_behave_like "Any forum categories"

  before do
    @controller.template.stub!(:current_user?).and_return(true)
    @controller.template.stub!(:current_user).and_return(@user = mock("mock user"))
    @user.stub!(:can?).and_return(true)
  end

  it "should render a link to add a new category" do
    do_render
    response.should have_tag("a[href$=?]", new_forum_category_path, :text => /Add New Category/i)
  end

  it "should render a link to add a new forum" do
    do_render
    response.should have_tag("a[href$=?]", new_forum_path(@forum_category), :text => /Add New Forum/i)
  end

  it "should render a link to add a new topic" do
    do_render
    response.should have_tag("a[href$=?]", new_topic_path(@forum_category, @forum), :text => /Add New Topic/i)
  end

  it "should render a link to add a new post" do
    do_render
    response.should have_tag("a[href$=?]", new_post_path(@forum_category, @forum, @topic), :text => /Reply/i)
  end

  def do_render
    render "forum_categories/index"
  end
end

describe "forum_categories/index (logged-in, no read restrictions, with write restrictions, non-admin)" do
  it_should_behave_like "Any forum categories"

  before do
    @controller.template.stub!(:current_user?).and_return(true)
    @controller.template.stub!(:current_user).and_return(@user = mock("mock user"))
    @user.stub!(:can?).and_return(false)

    @forum.stub!(:readable_by?).and_return(false)
    @forum.stub!(:writeable_by?).and_return(false)
  end

  it "should not render a link to add a new category" do
    do_render
    response.should_not have_tag("a[href$=?]", :text => /Add New Category/i)
  end

  it "should not render a link to add a new forum" do
    do_render
    response.should_not have_tag("a[href$=?]", :text => /Add New Forum/i)
  end

  it "should not render a link to add a new topic" do
    do_render
    response.should_not have_tag("a[href$=?]", new_topic_path(@forum_category, @forum), :text => /Add New Topic/i)
  end

  it "should not render a link to add a new post" do
    do_render
    response.should_not have_tag("a[href$=?]", new_post_path(@forum_category, @forum, @topic), :text => /Reply/i)
  end

  def do_render
    render "forum_categories/index"
  end
end
