require File.dirname(__FILE__) + '/../test_helper'

class TimeCalculationsRoundingTest < Test::Unit::TestCase
  def test_rounds_to_nearest_thirty_minute_slot
    assert_equal 9.hours,
        TimeCalculations::round(time(:hour => 9, :min => 15), 8.hours, 30.minutes)
  end

  def test_rounds_to_nearest_fifteen_minute_slot_in_middle
    assert_equal 9.hours + 15.minutes,
        TimeCalculations::round(time(:hour => 9, :min => 27), 8.hours, 15.minutes)
  end

  def test_rounds_to_nearest_fifteen_minute_slot_at_end
    assert_equal 9.hours + 15.minutes,
        TimeCalculations::round(time(:hour => 9, :min => 29), 8.hours, 15.minutes)
  end

  def test_rounds_to_nearest_fifteen_minute_slot_at_start
    assert_equal 9.hours + 15.minutes,
        TimeCalculations::round(time(:hour => 9, :min => 15), 8.hours, 15.minutes)
  end

  def test_rounds_to_nearest_fifteen_minute_slot_at_next
    assert_equal 9.hours + 30.minutes,
        TimeCalculations::round(time(:hour => 9, :min => 30), 8.hours, 15.minutes)
  end

  def test_rounds_to_nearest_three_hour_slot_in_middle
    assert_equal 8.hours,
        TimeCalculations::round(time(:hour => 9, :min => 30), 8.hours, 3.hours)
  end

  def test_rounds_to_nearest_three_hour_slot_at_start
    assert_equal 8.hours,
        TimeCalculations::round(time(:hour => 8, :min => 0), 8.hours, 3.hours)
  end

  def test_rounds_to_nearest_three_hour_slot_at_end
    assert_equal 8.hours,
        TimeCalculations::round(time(:hour => 10, :min => 59), 8.hours, 3.hours)
  end

  protected
  def time(*args)
    Time.now.change(*args)
  end
end
