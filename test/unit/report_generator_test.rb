require File.dirname(__FILE__) + '/../test_helper'

class ReportGeneratorTest < Test::Unit::TestCase
  def test_correct_returns
    report_lines = []
    report_line = ReportContainsLine.new
    report_line.field = "name"
    report_line.value = "wreath"
    report_lines << report_line
    products = accounts(:wpul).products.to_report_sql(report_lines)
    assert_equal 2, products.size
  end
end
