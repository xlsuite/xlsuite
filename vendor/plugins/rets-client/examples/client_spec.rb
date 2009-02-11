require "xl_suite/rets/client"

# Mock out the RETS4R::Client
module RETS4R
  class Client; end
end

describe XlSuite::Rets::Client do
  before do
    @rets_client = mock("RETS Client")
    @rets_client.stub!(:rets_version=)
    @rets_client.stub!(:set_pre_request_block)

    RETS4R::Client.stub!(:new).and_return(@rets_client)
  end

  def do_instantiation(options={})
    XlSuite::Rets::Client.new("http://some-url.com/login", options).new_client
  end

  it "should instantiate a new RETS4R::Client with the correct login URL when calling #new_client" do
    RETS4R::Client.should_receive(:new).with("http://some-url.com/login").and_return(@rets_client)
    do_instantiation
  end

  it "should set the user agent" do
    @rets_client.should_receive(:user_agent=).with("my-client/1.2")
    do_instantiation(:user_agent => "my-client/1.2")
  end

  it "should set the logger" do
    @rets_client.should_receive(:logger=).with(:a_logger)
    do_instantiation(:logger => :a_logger)
  end

  it "should set the RETS version" do
    @rets_client.should_receive(:rets_version=).with("1.7")
    do_instantiation
  end
end

describe XlSuite::Rets::Client, "#transaction" do
  before do
    @rets_client = mock("RETS Client")
    @rets_client.stub!(:rets_version=)
    @rets_client.stub!(:set_pre_request_block)

    RETS4R::Client.stub!(:new).and_return(@rets_client)
    @rets_client.stub!(:login).and_yield
  end

  def do_instantiation(options={})
    XlSuite::Rets::Client.new("http://some-url.com/login", options)
  end

  it "should execute #transaction within a login block" do
    @rets_client.should_receive(:login).with("a", "b").and_yield
    do_instantiation(:username => "a", :password => "b").transaction do
      # NOP
    end
  end

  it "should yield to the transaction, and return the transaction's value" do
    do_instantiation.transaction do
      :ran
    end.should == :ran
  end

  it "should yield an XlSuite::Rets::RetsClient" do
    do_instantiation.transaction do |client|
      client.should be_kind_of(XlSuite::Rets::RetsClient)
    end
  end
end
