require "xl_suite/rets/rets_client"

describe XlSuite::Rets::RetsClient, "#initialize" do
  it "should accept a RETS4R::Client" do
    lambda { XlSuite::Rets::RetsClient.new(mock("client")) }.should_not raise_error
  end
end

describe XlSuite::Rets::RetsClient, "#lookup" do
  before do
    @rets = mock("rets4r-client")
    @client = XlSuite::Rets::RetsClient.new(@rets)

    @txn = mock("txn")
    @txn.stub!(:success?).and_return(true)
  end

  it "should do a metadata lookup with the passed-in type" do
    @txn.stub!(:data).and_return(meta = [[]])
    @rets.should_receive(:get_metadata).with("METADATA-LOOKUP_TYPE", "Property:141").and_yield(@txn)

    @client.lookup(:lookup_type, "Property:141")
  end

  it "should yield the data to the block if the request is successful and return the block's value" do
    data = [{"MetadataEntryID" => "8456", "LongValue" => "Air Cond./Central", "Value" => "AIRCO", "ShortValue" => "AIRCO"}]
    @txn.stub!(:data).and_return([data])
    @txn.stub!(:success?).and_return(true)
    @rets.should_receive(:get_metadata).with("METADATA-LOOKUP_TYPE", "Property:141").and_yield(@txn)

    @client.lookup(:lookup_type, "Property:141") do |block_data|
      block_data.should == [data]
      :yielded
    end.should == :yielded
  end

  it "should return an empty array if no metadata is returned" do
    @txn.stub!(:data).and_return([])
    @rets.should_receive(:get_metadata).with("METADATA-LOOKUP_TYPE", "User:217").and_yield(@txn)

    @client.lookup(:lookup_type, "User:217").should == []
  end
end

describe XlSuite::Rets::RetsClient, "#search" do
  before do
    @rets = mock("rets4r-client")
    @client = XlSuite::Rets::RetsClient.new(@rets)
    @txn = mock("txn")
    @txn.stub!(:success?).and_return(true)
  end

  it "should accept the query and class" do
    @rets.stub!(:search).and_return(nil)
    @client.search("Property", "11", "(43=|V)")
  end

  it "should query the rets implementation using the same parameters" do
    @rets.should_receive(:search).with("Property", "11", "(43=|V)", {}).and_yield(@txn)
    @txn.stub!(:data).and_return([])
    @client.search("Property", "11", "(43=|V)")
  end

  it "should yield each result one by one" do
    properties = [{"2681" => "999-111-2222"}]
    @rets.should_receive(:search).with("Property", "9", "(363=A)", {}).and_yield(@txn)
    @txn.should_receive(:data).and_return(properties)
    count = 0
    @client.search("Property", "9", "(363=A)") do |property|
      property.should == properties.first
      count.should == 0
      count += 1
    end

    count.should == 1
  end

  it "should return the result of each block value in an array" do
    properties = [{"2681" => "000-111-2222"}]
    @rets.should_receive(:search).with("Property", "9", "(364=A)", {}).and_yield(@txn)
    @txn.should_receive(:data).and_return(properties)
    @client.search("Property", "9", "(364=A)") do |property|
      property.should == properties.first
      true
    end.should == [true]
  end
end

describe XlSuite::Rets::RetsClient, "#get_photos" do
  before do
    @rets = mock("rets4r-client")
    @client = XlSuite::Rets::RetsClient.new(@rets)
  end

  it "should call the RETS4R with the correct parameters" do
    @rets.should_receive(:get_object).with("Property", "Photo", "2458778:*", 0).and_yield([])
    @client.get_photos(:property, "2458778") {}
  end

  it "should yield the binary data as well as the returned options" do
    @rets.stub!(:get_object).and_yield([object = mock("data object")])
    object.stub!(:data).and_return(:image_binary_data)
    object.stub!(:type).and_return(img_options = {"Content-ID" => "2123", "Object-ID" => "1"})
    @client.get_photos(:property, "291012") do |image, options|
      image.should == :image_binary_data
      options.should == img_options
    end
  end

  it "should complain if no block given" do
    lambda { @client.get_photos(:property, "") }.should raise_error(ArgumentError)
  end
end
