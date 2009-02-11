require File.dirname(__FILE__) + '/../../spec_helper'

describe "/assets/edit" do
  before do
    assigns[:asset] = @asset = mock_model(Asset,
        :dom_id => "asset_1231", :title => "", :description => "", :tag_list => "")
    @form_id = @asset.dom_id
    assigns[:common_tags] = []
    render 'assets/edit'
  end

  it "should have a form named #asset_#{@form_id}" do
    response.should have_tag("form[id=?]", @form_id)
  end

  it "should have a form that POSTs" do
    response.should have_tag("form[id=?][method=post]", @form_id)
  end

  it "should have a form that specifies the multipart encoding" do
    response.should have_tag("form[id=?][enctype=multipart/form-data]", @form_id)
  end

  it "should have a form whose action is the specific asset URL" do
    response.should have_tag("form[id=?][action$=?]", @form_id, asset_path(@asset))
  end

  it "should have fields to describe the new asset" do
    response.should have_tag("form[id=?]", @form_id) do
      with_tag "input#asset_uploaded_data[type=file][name=?]", "asset[uploaded_data]"
      with_tag "#asset_title[name=?]", "asset[title]"
      with_tag "#asset_tag_list[name=?]", "asset[tag_list]"
      with_tag "#asset_description[name=?]", "asset[description]"
    end
  end

  it "should have a submit button" do
    response.should have_tag("form[id=?]", @form_id) do
      with_tag "input[type=submit][value=Save]"
    end
  end

  it "should have a cancel link" do
    response.should have_tag("form[id=?]", @form_id) do
      with_tag "a[href$=?]", asset_path(@asset), /Cancel/i
    end
  end
end
