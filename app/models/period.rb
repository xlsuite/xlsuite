#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Period
  ValidUnits = %w(minutes hours days weeks months years)

  attr_accessor :length, :unit

  def initialize(length, unit)
    @length = length.to_i

    case unit.to_s
    when /^min(utes?)?$/
      @unit = "minutes"
    when /^h(ours?)?$/
      @unit = "hours"
    when /^d(ays?)?$/
      @unit = "days"
    when /^w(eeks?)?$/
      @unit = "weeks"
    when /^m(onths?)?$/
      @unit = "months"
    when /^y(ears?)?$/
      @unit = "years"
    else
      raise ArgumentError, "Unable to understand unit #{unit.inspect}"
    end
  end

  def to_s
    if @length.zero? || @length > 1 then
      "%d %s" % [@length, @unit]
    else
      "%d %s" % [@length, @unit.singularize]
    end
  end

  def as_seconds
    self.length.send(self.unit)
  end

  def to_i
    self.as_seconds
  end

  def to_f
    self.as_seconds.to_f
  end

  # Compare number of seconds
  def ==(other)
    self.as_seconds == other.as_seconds
  end

  def hash
    self.as_seconds.hash
  end

  class << self
    def parse(string)
      return nil if string.blank?
      
      case string.strip
      when /\A(\d+)\s*((min(utes?)?)|(h(ours?)?)|(d(ays?)?)|(w(eeks?)?)|(m(onths?)?)|(y(ears?)?))\Z/
        self.new($1.to_i, $2)
      else
        raise ArgumentError, "format must be n minutes/days/weeks/months/years, where n is a number"
      end
    end
  end
end
