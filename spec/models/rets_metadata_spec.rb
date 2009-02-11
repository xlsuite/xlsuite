require File.dirname(__FILE__) + '/../spec_helper'

describe RetsMetadata do
  before(:each) do
    @rets_metadata = RetsMetadata.new
  end

  it "should be invalid if missing the name" do
     @rets_metadata.should have(1).errors_on(:name)
  end

  it "should be invalid if missing the version" do
     @rets_metadata.should have(1).errors_on(:version)
  end

  it "should be invalid if missing the date" do
     @rets_metadata.should have(1).errors_on(:date)
  end

  it "should be invalid if a duplicate name is used" do
    @rets_metadata.name = "Lookup:317"
    @rets_metadata.save(false)

    @rets_metadata = RetsMetadata.new(:name => "Lookup:317")
    @rets_metadata.should have(1).errors_on(:name)
  end

  it "should serialize the #values attribute" do
    @rets_metadata.values = {:a => "b", :c => "d"}
    @rets_metadata.save(false)
    @rets_metadata.reload.values.should == {:a => "b", :c => "d"}
  end
end
