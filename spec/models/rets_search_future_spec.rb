require File.dirname(__FILE__) + "/../spec_helper"
require "ostruct"

describe RetsSearchFuture, "#parse" do
  it "should parse a line of 'MLS No exactly equals 90392' into (247=90392)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "MLS No", :value => "247", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "247", :operator => "eq", :from => "90392", :to => ""}]).should == "(247=90392)"
  end

  it "should parse a line of 'Neighborhood exactly equals AB' into (478=AB)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Neighborhood", :value => "478", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "478", :operator => "eq", :from => "AB", :to => ""}]).should == "(478=AB)"
  end

  it "should parse a line of 'Total square footage greater than 1000' into (832=1000+)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Total square footage", :value => "832", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "832", :operator => "greater", :from => "1000", :to => ""}]).should == "(832=1000+)"
  end

  it "should parse a line of 'Total square footage lower than 900' into (954=900-)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Total square footage", :value => "954", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "954", :operator => "less", :from => "900", :to => ""}]).should == "(954=900-)"
  end

  it "should parse a line of 'Total square footage between 800 and 1000' into (954=800-1000)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Total square footage", :value => "954", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "954", :operator => "between", :from => "800", :to => "1000"}]).should == "(954=800-1000)"
  end

  it "should parse a line of 'Address contains XYZ' into (773=*XYZ*)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Address", :value => "773", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "773", :operator => "contain", :from => "XYZ", :to => ""}]).should == "(773=*XYZ*)"
  end

  it "should parse a line of 'Address starts with XYZ' into (773=XYZ*)" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Address", :value => "773", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "773", :operator => "start", :from => "XYZ", :to => ""}]).should == "(773=XYZ*)"
  end

  it "should parse a Chronic date specification within parentheses in 'from' into a real date" do
    date = Chronic.parse("yesterday").to_date.to_s(:iso)
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Listing Date", :value => "5478", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "5478", :operator => "greater", :from => "(yesterday)", :to => ""}]).should == "(5478=#{date}+)"
  end

  it "should parse a Chronic date specification within parentheses in 'to' into a real date" do
    from = Chronic.parse("yesterday").to_date.to_s(:iso)
    to = Chronic.parse("today").to_date.to_s(:iso)
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Listing Date", :value => "5478", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "5478", :operator => "between", :from => "(yesterday)", :to => "(today)"}]).should == "(5478=#{from}-#{to})"
  end

  it "should parse two lines into the equivalent ANDed query" do
    date = Chronic.parse("yesterday").to_date.to_s(:iso)
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [ OpenStruct.new(:description => "Listing Date", :value => "5478", :lookup_name => ""),
          OpenStruct.new(:description => "Status", :value => "9299", :lookup_name => "")])

    RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
        [{:field => "5478", :operator => "greater", :from => "(yesterday)", :to => ""},
          {:field => "9299", :operator => "eq", :from => "A", :to => ""}]).should == "(5478=#{date}+),(9299=A)"
  end

  it "should raise a RetsSearchFuture::UnknownFieldError when the requested field cannot be found" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return([])

    lambda {
      RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
          [{:field => "Listing Date", :operator => "greater", :from => "(yesterday)", :to => ""}])
    }.should raise_error(RetsSearchFuture::UnknownFieldError)
  end

  it "should raise a RetsSearchFuture::SyntaxError when the operator is unknown" do
    RetsMetadata.should_receive(:find_all_fields).with("Property", "11").and_return(
        [OpenStruct.new(:description => "Listing Date", :value => "5478", :lookup_name => "")])

    lambda {
      RetsSearchFuture.parse({:resource => "Property", :class => "11", "limit" => "5"},
          [{:field => "5478", :operator => "within", :from => "(yesterday)", :to => "(today)"}])
    }.should raise_error(RetsSearchFuture::SyntaxError)
  end
end

describe RetsSearchFuture do
  it "should be invalid if an unknown field is given" do
    RetsMetadata.stub!(:find_all_fields).and_return([])
    rets = RetsSearchFuture.new(:account => mock_account, :owner => mock_party,
        :args => {:search => {:class => "11", :resource => "Property"},
          :lines => [{:field => "9998", :operator => "eq", :from => ".EMPTY.", :to => ""}]})
    rets.should_not be_valid
    rets.should have(1).errors
  end

  it "should be invalid if an unknown operator is given" do
    RetsMetadata.stub!(:find_all_fields).and_return([OpenStruct.new(:description => "Listing Date", :value => "5478", :lookup_name => "")])
    rets = RetsSearchFuture.new(:account => mock_account, :owner => mock_party,
        :args => {:search => {:class => "11", :resource => "Property"},
          :lines => [{:field => "5478", :operator => "within", :from => "(yesterday)", :to => "(today)"}]})
    rets.should_not be_valid
    rets.should have(1).errors
  end
end
