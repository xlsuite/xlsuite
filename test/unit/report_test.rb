require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < Test::Unit::TestCase
  setup do
    @report = accounts(:wpul).reports.build
  end

  should "generate ReportLine instances when calling \#lines=" do
    @report.lines = {"1" => {"field" => "First name", "operator" => "ReportContainsLine", "value" => "abc"}, 
      "11" => {"field" => "Last name", "operator" => "ReportContainsLine", "value" => "a", "excluded" => "1"}, 
      "2" => {"field" => "Middle name", "operator" => "ReportContainsLine", "value" => "b"}
    }

    assert_equal [
      ReportContainsLine.new(:field => "First name", :value => "abc"),
      ReportContainsLine.new(:field => "Middle name", :value => "b"),
      ReportContainsLine.new(:field => "Last name", :value => "a", :excluded => "1")], @report.lines
  end
end
