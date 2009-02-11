require "#{File.dirname(__FILE__)}/../test_helper"

class EstimateXmlTest < ActionController::IntegrationTest
  include XlSuiteIntegrationHelpers

  setup do
    host! "test.host"
    @estimate = Estimate.find(:first)
  end

  context "POSTing XML to /admin/estimates" do
    setup do
      @estimate_count = Estimate.count
      post "/admin/estimates", @estimate.to_xml, {:content_type => "text/xml"}
    end

    should "create a new estimate properly" do
      assert_equal @estimate_count + 1, Estimate.count
    end
  end
end
