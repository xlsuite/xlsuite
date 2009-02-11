require File.dirname(__FILE__) + '/../spec_helper'

describe AssetsHelper, "#with_thumbnail" do
  before do
    @asset = mock_model(Asset, :filename => "piston.jpg", :width => 938, :height => 547,
        :size => 17291, :content_type => "image/jpeg")

    @asset.stub!(:thumbnails).and_return(@thumbnails = collection_proxy())
    @thumbnails.stub!(:find_by_thumbnail).and_return(nil)

    stub!(:capture)
    stub!(:concat)
  end

  it "should attempt to find a thumbnail with the named size" do
    @asset.should_receive(:thumbnails).with().and_return(@thumbnails)
    @thumbnails.should_receive(:find_by_thumbnail).with("square").and_return(nil)
    with_thumbnail(@asset, :square) {}
  end

  it "should submit the original asset to the block when no thumbnail found" do
    should_receive(:capture).with(@asset, download_asset_path(@asset))
    with_thumbnail(@asset, :square) {}
  end

  it "should submit the thumbnail with the thumbnail's URL to the block when the thumbnail found" do
    @thumbnails.stub!(:find_by_thumbnail).and_return(thumb = mock_model(Asset))

    should_receive(:capture).with(thumb, download_asset_path(:id => @asset, :size => "square"))
    with_thumbnail(@asset, :square) {}
  end

  it "should #concat whatever #capture returns" do
    stub!(:capture).and_return(:some_complicated_html)
    should_receive(:concat).with(:some_complicated_html, anything)
    with_thumbnail(@asset, :square) {}
  end
end
