#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module TimeCalculations
  # Rounds the given time according to <tt>start_time</tt> and
  # <tt>precision_in_seconds</tt>.
  #
  # == Examples
  #  TimeCalculations::round(9.hours + 15.minutes, 8.hours, 30.minutes) #=> 9.hours
  #  TimeCalculations::round(9.hours + 27.minutes, 8.hours, 15.minutes) #=> 9.hours + 15.minutes
  #  TimeCalculations::round(9.hours + 27.minutes, 8.hours, 2.hours) #=> 8.hours
  #
  # == Warnings
  # This method ignores secods in it's calculations
  def self.round(time, start_time, precision_in_seconds)
    (start_time ... 24.hours).step(precision_in_seconds) do |slot_start|
      slot = (slot_start ... slot_start+precision_in_seconds)
      return slot_start if slot.include?(time.hour.hours + time.min.minutes)
    end
  end
end
