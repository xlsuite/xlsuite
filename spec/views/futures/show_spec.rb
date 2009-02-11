require File.dirname(__FILE__) + "/../../spec_helper.rb"

describe "Futures#show" do
  before do
    @started_at = 2.seconds.ago
    @future = mock_future(:status => "started", :started_at => @started_at)

    assigns[:future] = @future
    assigns[:refresh_interval] = 1.minute
    assigns[:status] = "status"
    assigns[:elapsed] = "elapsed"
    assigns[:progress] = "progress"
    render "/futures/show"
  end

  it "should display the current status in #status" do
    response.should have_tag("#status", "started")
  end

  it "should have a throbber named #throbber" do
    response.should have_tag("img#throbber[src^=/images/throbber.gif]")
  end

  it "should have an #elapsed element" do
    response.should have_tag("#elapsed", /a few seconds ago/i)
  end

  it "should have a #refresh_interval element" do
    response.should have_tag("input#refresh_interval[type=hidden][value=?]", assigns[:refresh_interval] * 1000)
  end
end

describe "Futures#show", "when not started" do
  before do
    @started_at = 2.seconds.ago
    @future = mock_future(:status => "unstarted", :started_at => nil)

    assigns[:future] = @future
    assigns[:refresh_interval] = 1.minute
    assigns[:elapsed] = "elapsed"
    render "/futures/show"
  end

  it "should say '0 seconds' elapsed" do
    response.should have_tag("#elapsed", "0 seconds")
  end
end
