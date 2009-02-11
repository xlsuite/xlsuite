require File.dirname(__FILE__) + '/../test_helper'

class ReportContainsLineTest < Test::Unit::TestCase
  def test_uses_like_as_operator
    assert_equal "LIKE", ReportContainsLine.new.operator
  end

  def test_returns_value_with_percents
    assert_equal "%A%", ReportContainsLine.new(:value => "A").value
  end
end
