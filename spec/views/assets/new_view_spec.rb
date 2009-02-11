require File.dirname(__FILE__) + '/../../spec_helper'

describe "/assets/new" do
  before do
    assigns[:asset] = Asset.new
    assigns[:common_tags] = []
    render 'assets/new'
  end

  it "should have a form named #new_asset" do
    response.should have_tag("form#new_asset")
  end

  it "should have a #new_asset form that POSTs" do
    response.should have_tag("form#new_asset[method=post]")
  end

  it "should have a #new_asset form that specifies the multipart encoding" do
    response.should have_tag("form#new_asset[enctype=multipart/form-data]")
  end

  it "should have a #new_asset form whose action is the assets collection URL" do
    response.should have_tag("form#new_asset[action$=?]", assets_path)
  end

  it "should have fields to describe the new asset" do
    response.should have_tag("form#new_asset") do
      with_tag "input#asset_uploaded_data[type=file][name=?]", "asset[uploaded_data]"
      with_tag "#asset_title[name=?]", "asset[title]"
      with_tag "#asset_tag_list[name=?]", "asset[tag_list]"
      with_tag "#asset_description[name=?]", "asset[description]"
    end
  end

  it "should have a submit button" do
    response.should have_tag("form#new_asset") do
      with_tag "input[type=submit][value=Upload]"
    end
  end

  it "should have a cancel link" do
    response.should have_tag("form#new_asset") do
      with_tag "a[href$=?]", assets_path, /Cancel/i
    end
  end
end
