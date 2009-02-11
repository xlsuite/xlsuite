require File.dirname(__FILE__) + "/../test_helper"

class PeriodTest < Test::Unit::TestCase
  context "A period of 14 days" do
    setup do
      @period = Period.new(14, "days")
    end

    should "have a unit of 'days'" do
      assert_equal "days", @period.unit
    end

    should "have a length of 14" do
      assert_equal 14, @period.length
    end

    should "have the same number of seconds as 14.days" do
      assert_equal 14.days, @period.as_seconds
    end

    should "be equal to itself" do
      assert @period == @period
    end

    should "return a string equal to '14 days'" do
      assert_equal "14 days", @period.to_s
    end
  end

  should "parse '12min' as 12 minutes" do
    assert_equal Period.new(12, "minutes"), Period.parse("12min")
  end

  should "parse '2h' as 2 hours" do
    assert_equal Period.new(2, "hours"), Period.parse("2h")
  end

  should "parse '14 d' as 14 days" do
    assert_equal Period.new(14, "days"), Period.parse("14 d")
  end

  should "parse '1w' as 1 week" do
    assert_equal Period.new(1, "week"), Period.parse("1w")
  end

  should "parse '3months ' as 3 months" do
    assert_equal Period.new(3, "months"), Period.parse("3months ")
  end

  should "parse ' 2 years' as 2 years" do
    assert_equal Period.new(2, "years"), Period.parse(" 2 years")
  end

  should "parse '' as nil" do
    assert_nil Period.parse("")
  end

  should "parse nil as nil" do
    assert_nil Period.parse(nil)
  end

  should "parse '  ' as nil" do
    assert_nil Period.parse("  ")
  end
end
