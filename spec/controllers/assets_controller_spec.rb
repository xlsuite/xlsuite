require File.dirname(__FILE__) + '/../spec_helper'

describe AssetsController, "#index" do
  it_should_behave_like "All authenticated controllers"

  before do
    @user.stub!(:assets).and_return(@assets = [])
    @account.stub!(:assets).and_return(@account_assets = [])
    @assets.stub!(:find_all_parents).and_return(@assets)
    @account_assets.stub!(:find_all_parents).and_return(@account_assets)
  end

  it "should find this user's assets" do
    @user.should_receive(:assets).and_return(@assets)
    @assets.should_receive(:find_all_parents).and_return([])
    get :index
  end

  it "should make available the assets in @assets" do
    get :index
    assigns(:assets).should == @assets
  end

  it "should search this user's assets" do
    @user.should_receive(:assets).and_return(@assets)
    @assets.should_receive(:find_all_parents).and_return([])
    get :index
    assigns(:assets).should == []
  end

  it "should be successful" do
    get :index
    response.should be_success
  end

  it "should render assets/index" do
    get :index
    response.should render_template("assets/index")
  end

  it "should find all assets when 'scope=all'" do
    @account.should_receive(:assets).and_return(@account_assets)
    @account_assets.should_receive(:find_all_parents).and_return([])
    get :index, :scope => "all"
  end

  it "should make all assets available in @assets when 'scope=all'" do
    get :index, :scope => "all"
    assigns(:assets).should == @account_assets
  end

  it "should filter the returned collection so unreadable assets aren't available" do
    @assets << a = mock_model(Asset, :readable_by? => false)
    @assets << b = mock_model(Asset, :readable_by? => true)
    get :index
    assigns(:assets).should == [b]
  end

  it "should search within user assets for assets with a specific tag with 'q=tag:name'" do
    @assets.should_receive(:find_tagged_with).with(:all => %w(name)).and_return([])
    get :index, :q => "tag:name"
  end
end

describe AssetsController, "#show" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = collection_proxy(@asset = mock_model(Asset)))
    @assets.stub!(:find).and_return(@asset)
    @assets.stub!(:tags).and_return(@tags = collection_proxy)
    @asset.stub!(:readable_by?).and_return(true)
  end

  it "should be successful" do
    get :show, :id => 8392
    response.should be_success
  end

  it "should render assets/show" do
    get :show, :id => 8393
    response.should render_template("assets/show")
  end

  it "should make the asset available in @asset" do
    @assets.should_receive(:find).with("8394").and_return(@asset)
    get :show, :id => 8394
    assigns(:asset).should == @asset
  end

  it "should return a 404 when the asset isn't readable by the current user" do
    @asset.should_receive(:readable_by?).with(@user).and_return(false)
    get :show, :id => 8395
    response.should be_missing
  end
end

describe AssetsController, "#show with an anonymous user" do
  it_should_behave_like "All controllers"

  before do
    @account.stub!(:assets).and_return(@assets = collection_proxy(@asset = mock_model(Asset)))
    @assets.stub!(:find).and_return(@asset)
    @assets.stub!(:tags).and_return([])
  end

  it "should redirect to download when the asset is publicly readable" do
    @asset.should_receive(:readable_by?).with(nil).and_return(true)
    get :show, :id => @asset.id
    response.should redirect_to(download_asset_path(@asset))
  end

  it "should render missing when the asset is not public" do
    @asset.should_receive(:readable_by?).with(nil).and_return(false)
    get :show, :id => 1231
    response.should be_missing
  end
end

describe AssetsController, "#download with an anonymous user" do
  it_should_behave_like "All controllers"

  before do
    @account.stub!(:assets).and_return(@assets = collection_proxy(@asset = mock_model(Asset)))
    @assets.stub!(:find).and_return(@asset)
    @asset.stub!(:readable_by?).and_return(true)

    @asset.stub!(:content_type).and_return("application/octet-stream")
    @asset.stub!(:filename).and_return("some-big-filename.txt")
    @asset.stub!(:current_data).and_return("this is the file's content")
  end

  it "should set the response's content type to the asset's" do
    @asset.should_receive(:content_type).with().at_least(:once).and_return("text/big+xml")

    get :download, :id => 8393
    response.headers["Content-Type"].should == "text/big+xml"
  end

  it "should send the asset's data inline" do
    @asset.should_receive(:current_data).and_return("this is the file's content")

    get :download, :id => 8393
    response.body.should == "this is the file's content"
  end

  it "should be successful when the asset is publicly readable" do
    @asset.should_receive(:readable_by?).at_least(:once).with(nil).and_return(true)
    get :download, :id => 1232
    response.should be_success
  end

  it "should be missing when the asset is NOT publicly readable" do
    @asset.should_receive(:readable_by?).at_least(:once).with(nil).and_return(false)
    get :download, :id => 1233
    response.should be_missing
  end

  it "should send the asset's data when accessed through the asset's filename" do
    @assets.should_receive(:find_by_filename).with(@asset.filename).and_return(@asset)

    get :download, :filename => @asset.filename
  end

  it "should be missing if no ID or filename is required" do
    get :download
    response.should be_missing
  end
end

describe AssetsController, "#download" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection(@asset = mock_model(Asset)))
    @assets.stub!(:find).and_return(@asset)
    @asset.stub!(:readable_by?).and_return(true)

    @asset.stub!(:content_type).and_return("application/octet-stream")
    @asset.stub!(:filename).and_return("some-big-filename.txt")
    @asset.stub!(:current_data).and_return("this is the file's content")
  end

  it "should be successful" do
    get :download, :id => 8392
    response.should be_success
  end

  it "should set the response's content type to the asset's" do
    @asset.should_receive(:content_type).with().at_least(:once).and_return("text/big+xml")

    get :download, :id => 8393
    response.headers["Content-Type"].should == "text/big+xml"
  end

  it "should send the asset's data inline" do
    @asset.should_receive(:current_data).with().and_return("this is the file's content")

    get :download, :id => 8393
    response.body.should == "this is the file's content"
  end

  it "should set the response's content disposition to 'attachment'" do
    get :download, :id => 8393
    response.headers["Content-Disposition"].should match(/^attachment/)
  end

  it "should set the response's content disposition to 'inline' if the content-type starts with 'text/'" do
    @asset.should_receive(:content_type).with().at_least(:once).and_return("text/plain")
    get :download, :id => 8393
    response.headers["Content-Disposition"].should match(/^inline/)
  end

  it "should set the response's content disposition to 'inline' if the content-type starts with 'image/'" do
    @asset.should_receive(:content_type).with().at_least(:once).and_return("image/jpeg")
    get :download, :id => 8393
    response.headers["Content-Disposition"].should match(/^inline/)
  end

  it "should set the response's content disposition to 'inline' if the content-type ends in 'xml'" do
    @asset.should_receive(:content_type).with().at_least(:once).and_return("application/xls+xml")
    get :download, :id => 8393
    response.headers["Content-Disposition"].should match(/^inline/)
  end

  it "should provide the asset's filename in the content disposition header" do
    @asset.should_receive(:filename).with().and_return("some-big-filename.txt")

    get :download, :id => 8393
    response.headers["Content-Disposition"].should match(/filename="some-big-filename\.txt"/)
  end

  it "should make the asset available in @asset" do
    @assets.should_receive(:find).with("8394").and_return(@asset)
    get :download, :id => 8394
    assigns(:asset).should == @asset
  end

  it "should find a thumbnail if the 'size' parameter is set to a known thumbnail name" do
    @asset.should_receive(:thumbnails).with().and_return(thumbs = mock_collection())
    thumbs.should_receive(:find_by_thumbnail).with("square").and_return(thumb = @asset)
    get :download, :id => 8395, :size => "square"
  end

  it "should return a 404 when the 'size' parameter is unknown" do
    @asset.stub!(:thumbnails).and_return(thumbs = mock_collection())
    thumbs.stub!(:find_by_thumbnail).and_return(nil)
    get :download, :id => 8395, :size => "1024x1024"
    response.should be_missing
  end

  it "should return a '404 Not Found' when the asset isn't readable by the current user" do
    @asset.should_receive(:readable_by?).with(@user).and_return(false)
    get :download, :id => 8395
    response.should be_missing
  end

  it "should return an X-Sendfile header if the environment contains X-Sendfile-Capable=1" do
    @request.env.merge!("HTTP_X_SENDFILE_CAPABLE" => "1")
    @asset.should_receive(:full_filename).with().at_least(:once).and_return("/full/path/to-file")

    get :download, :id => 8395
    response.headers["X-Sendfile"].should == "/full/path/to-file"
  end

  it "should return a very short response if the environment contains X-Sendfile-Capable=1" do
    @request.env.merge!("HTTP_X_SENDFILE_CAPABLE" => "1")
    @asset.stub!(:full_filename).and_return("/full/path/to-file")

    get :download, :id => 8395
    response.body.size.should < 5
  end
end

describe AssetsController, "#new" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:build).and_return(@asset = mock_model(Asset))
    @assets.stub!(:tags).and_return(@tags = collection_proxy())
  end
  
  it "should be successful" do
    get :new
    response.should be_success
  end

  it "should render 'assets/new'" do
    get :new
    response.should render_template("assets/new")
  end

  it "should build a new asset" do
    @assets.should_receive(:build).with().and_return(@asset)
    get :new
  end

  it "should make the asset available to the view" do
    get :new
    assigns(:asset).should == @asset
  end

  it "should find the most common tags on Assets" do
    @assets.should_receive(:tags).with(:order => "count DESC, name ASC").and_return([])
    get :new
  end

  it "should make the common tags accessible to the view in @common_tags" do
    @tags = collection_proxy(:tag1, :tag2)
    @assets.stub!(:tags).and_return(@tags)
    get :new
    assigns(:common_tags).should == @tags
  end
end

describe AssetsController, "#create" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:build).and_return(@asset = mock_model(Asset))
    @assets.stub!(:tags).and_return([])
    @asset.stub!(:owner=)
    @asset.stub!(:save).and_return(true)
  end

  def params(options={})
    {:asset => {:title => "A nice little picture",
        :description => "This is a picture of my dog, when he was little and not too big.",
        :uploaded_data => fixture_file_upload("/large.jpg", "image/jpeg")}}.merge(options)
  end

  def do_post(parameters=params)
    post :create, parameters
  end

  it "should update the tag_list separately" do
    @asset.should_receive(:tag_list=).with("dog cute").and_return(true)
    parameters = params
    parameters[:asset][:tag_list] = "dog cute"
    post :create, parameters
  end

  it "should build a new asset using the parameters" do
    p = params
    @assets.should_receive(:build).with(p[:asset].stringify_keys).and_return(@asset)
    do_post(p)
  end

  it "should save the asset" do
    @asset.should_receive(:save).with(no_args).and_return(true)
    do_post
  end

  it "should redirect to #show" do
    do_post
    response.should redirect_to(asset_path(assigns(:asset)))
  end

  it "should render 'assets/new' if there were validation errors" do
    @asset.stub!(:save).and_return(false)
    do_post
    response.should render_template("assets/new")
  end

  it "should make the asset available to the view as @asset" do
    do_post
    assigns(:asset).should == @asset
  end

  it "should make the asset's owner the current user" do
    @asset.should_receive(:owner=).with(@user)
    do_post
  end
end

describe AssetsController, "#edit" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:find).and_return(@asset = mock_model(Asset))
    @assets.stub!(:tags).and_return(@tags = collection_proxy())
    @asset.stub!(:readable_by?).and_return(true)
  end

  it "should find the right asset" do
    @assets.should_receive(:find).with("2123").and_return(@asset)
    get :edit, :id => 2123
  end

  it "should make the asset available to the view" do
    get :edit, :id => 2124
    assigns(:asset).should == @asset
  end

  it "should be successful" do
    get :edit, :id => 2125
    response.should be_success
  end

  it "should render 'assets/edit'" do
    get :edit, :id => 2126
    response.should render_template("assets/edit")
  end

  it "should render a 404 if the asset isn't readable by the current user" do
    @asset.stub!(:readable_by?).and_return(false)
    get :edit, :id => 2127
    response.should be_missing
  end

  it "should ensure the asset is readable by the current user" do
    @asset.should_receive(:readable_by?).with(@user).and_return(true)
    get :edit, :id => 2127
  end

  it "should return a '404 Not Found' response if the asset isn't readable by the current user" do
    @asset.stub!(:readable_by?).and_return(false)
    get :edit, :id => 2128
    response.should be_missing
  end

  it "should find the most common tags on Assets" do
    @assets.should_receive(:tags).with(:order => "count DESC, name ASC").and_return([])
    get :edit, :id => 2129
  end

  it "should make the common tags accessible to the view in @common_tags" do
    @tags = collection_proxy(:tag1, :tag2)
    @assets.stub!(:tags).and_return(@tags)
    get :edit, :id => 2130
    assigns(:common_tags).should == @tags
  end
end

describe AssetsController, "#update using XHR" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:find).and_return(@asset = mock_model(Asset))
    @assets.stub!(:tags).and_return([])
    @asset.stub!(:readable_by?).and_return(true)
    @asset.stub!(:writeable_by?).and_return(true)
    @asset.stub!(:update_attributes).and_return(true)
    @asset.stub!(:tag_list=).and_return(true)
  end

  def do_post(attribute=:title, value="a new title", params={})
    xhr :post, :update, {:id => 1231, :asset => {attribute => value}}.merge(params)
  end

  it "should render 'assets/update.rjs'" do
    do_post
    response.should render_template("assets/update")
  end

  it "should make the single attribute available to the view" do
    do_post :description, "this is the new description"
    assigns[:attribute].should == "description"
  end

  it "should ensure the asset is readable by the current user" do
    @asset.should_receive(:readable_by?).with(@user).and_return(true)
    do_post
  end

  it "should ensure the asset is writeable by the current user" do
    @asset.should_receive(:writeable_by?).with(@user).and_return(true)
    do_post
  end

  it "should return a '404 Not Found' response if the asset isn't readable by the current user" do
    @asset.stub!(:readable_by?).and_return(false)
    do_post
    response.should be_missing
  end

  it "should return a '401 Unauthorized' response if the asset isn't writeable by the current user" do
    @asset.stub!(:writeable_by?).and_return(false)
    do_post
    response.should be_unauthorized
  end
end

describe AssetsController, "#update" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:find).and_return(@asset = mock_model(Asset))
    @asset.stub!(:readable_by?).and_return(true)
    @asset.stub!(:writeable_by?).and_return(true)
    @asset.stub!(:update_attributes).and_return(true)
    @asset.stub!(:tag_list=).and_return(true)
  end

  def params(options={})
    {:id => 213, :asset => {:title => "A nice little picture",
        :description => "This is a picture of my dog, when he was little and not too big.",
        :uploaded_data => fixture_file_upload("/large.jpg", "image/jpeg")}}.merge(options)
  end

  def do_post(parameters=params)
    post :update, parameters
  end

  it "should find the right asset" do
    parameters = params
    parameters[:id] = 3422
    @assets.should_receive(:find).with("3422").and_return(@asset)
    do_post parameters
  end

  it "should make the asset available to the view" do
    do_post
    assigns(:asset).should == @asset
  end

  it "should render 'assets/edit' if save fails" do
    @assets.stub!(:tags)
    @asset.stub!(:update_attributes).and_return(false)
    do_post
    response.should render_template("assets/edit")
  end

  it "should find common tags if the save fails" do
    @asset.stub!(:update_attributes).and_return(false)
    @assets.should_receive(:tags).and_return(@tags)
    do_post
  end

  it "should make the common tags available in @common_tags if the save fails" do
    @assets.stub!(:tags)
    @asset.stub!(:update_attributes).and_return(false)
    do_post
    assigns[:common_tags].should == @tags
  end

  it "should ensure the asset is readable by the current user" do
    @asset.should_receive(:readable_by?).with(@user).and_return(true)
    do_post
  end

  it "should ensure the asset is writeable by the current user" do
    @asset.should_receive(:writeable_by?).with(@user).and_return(true)
    do_post
  end

  it "should return a '404 Not Found' response if the asset isn't readable by the current user" do
    @asset.stub!(:readable_by?).and_return(false)
    do_post
    response.should be_missing
  end

  it "should return a '401 Unauthorized' response if the asset isn't writeable by the current user" do
    @asset.stub!(:writeable_by?).and_return(false)
    do_post
    response.should be_unauthorized
  end

  it "should update the asset's attributes with the new values" do
    p = params
    @asset.should_receive(:update_attributes).with(p[:asset].stringify_keys).and_return(true)
    do_post(p)
  end

  it "should redirect to the asset's page" do
    do_post
    response.should redirect_to(asset_path(@asset))
  end
end

describe AssetsController, "#destroy" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:find).and_return(@asset = mock_model(Asset))
    @assets.stub!(:tags).and_return(@tags = [])
    @asset.stub!(:readable_by?).and_return(true)
    @asset.stub!(:writeable_by?).and_return(true)
    @asset.stub!(:destroy).and_return(true)
  end

  def params(options={})
    {:id => 213}.merge(options)
  end

  def do_delete(parameters=params)
    delete :destroy, parameters
  end

  it "should find the right asset" do
    @assets.should_receive(:find).with("6547").and_return(@asset)
    do_delete :id => 6547
  end

  it "should ensure the asset is readable by the current user" do
    @asset.should_receive(:readable_by?).with(@user).and_return(true)
    do_delete
  end

  it "should ensure the asset is writeable by the current user" do
    @asset.should_receive(:writeable_by?).with(@user).and_return(true)
    do_delete
  end

  it "should return a '404 Not Found' response if the asset isn't readable by the current user" do
    @asset.stub!(:readable_by?).and_return(false)
    do_delete
    response.should be_missing
  end

  it "should return a '401 Unauthorized' response if the asset isn't writeable by the current user" do
    @asset.stub!(:writeable_by?).and_return(false)
    do_delete
    response.should be_unauthorized
  end

  it "should redirect to #index" do
    do_delete
    response.should redirect_to(assets_path)
  end

  it "should destroy the asset" do
    @asset.should_receive(:destroy).and_return(true)
    do_delete
  end

  it "should render 'assets/edit' if the asset wasn't destroyed" do
    @asset.stub!(:destroy).and_return(false)
    do_delete
    response.should render_template("assets/edit")
  end

  it "should query the common tags if the asset isn't saved" do
    @asset.stub!(:destroy).and_return(false)
    @assets.should_receive(:tags).and_return([])
    do_delete
  end

  it "should make the common tags available to the view in @common_tags" do
    @asset.stub!(:destroy).and_return(false)
    do_delete
    assigns[:common_tags].should == @tags
  end
end

describe AssetsController, "#auto_complete_tag" do
  it_should_behave_like "All authenticated controllers"

  before do
    @account.stub!(:assets).and_return(@assets = mock_collection)
    @assets.stub!(:tags_like).and_return(@tags = [mock_model(Tag)])
  end

  it "should find tags like the q parameter" do
    @assets.should_receive(:tags_like).with("anim").and_return([])
    get :auto_complete_tag, :q => "anim"
  end

  it "should make the found tags available to the view as @tags" do
    get :auto_complete_tag, :q => "anim"
    assigns[:tags].should == @tags
  end

  it "should render 'tags/auto_complete'" do
    get :auto_complete_tag, :q => "anim"
    response.should render_template("tags/auto_complete")
  end
end
