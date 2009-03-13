#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Geolocatable
  def self.included(base) #:nodoc:
    base.send :include, InstanceMethods
    base.send :extend, ClassMethods
  end

  module InstanceMethods
    # Returns an instance of Distance that can format itself nicely.
    def distance
      Distance.new(distance_value, distance_unit)
    end

    # Returns the distance in kilometers or miles, depending on how we were searched.
    def distance_value
      respond_to?(:distance_in_kilometers) ? distance_in_kilometers : (respond_to?(:distance_in_miles) ? distance_in_miles : nil)
    end

    # Returns the unit the distances are returned in.
    def distance_unit
      respond_to?(:distance_in_kilometers) ? "km" : (respond_to?(:distance_in_miles) ? "miles" : "")
    end
  end

  module ClassMethods
    # Maps a variety of string or symbols to a normalized set of responses: :miles or :kilometers.
    # Basically, km, kilometer, mile and m (and their plural forms) are all accepted values.  Anything else raises an ArgumentError.
    def map_geo_unit(unit)
      case unit.to_s
      when /^m(?:iles?)?$/i
        :miles
      when /^k(?:m|(?:ilometers?))$/i
        :kilometers
      else
        raise ArgumentError, "Invalid unit: expected miles or kilometers, found #{unit}"
      end
    end

    # Instantiates two named scopes on the current class.
    # The first scope is named "nearest" and returns instances in order of distance from a specified point.
    # Call with latitude, longitude and options (in this order).
    #
    # The second scope is named "within" and returns instances within a specified distance of a specified point.
    # Call with maximum distance, and options.
    #
    # == Examples
    #
    #  class Address < ActiveRecord::Base
    #    acts_as_geolocatable
    #  end
    #
    #  # Returns an Array of instances near this point, with distances returned in miles (the default).
    #  Address.nearest(45.123, -120.3282)
    #  Address.nearest(45.123, -120.3282, :unit => :kilometers)
    #
    #  # Returns an Array of instances that are within the specified circle.
    #  Address.within(50, :unit => :kilometers, :of => [45.123, -120.3282])
    def acts_as_geolocatable
      named_scope :nearest, lambda {|*args|
        options = args.extract_options!
        options.reverse_merge!(:unit => :miles)
        latitude, longitude = args
        unit = map_geo_unit(options[:unit])
        distance_sql = Graticule::Distance::Spherical.to_sql(:latitude => latitude, :longitude => longitude, :latitude_column => "#{table_name}.latitude", :longitude_column => "#{table_name}.longitude", :units => unit)
        {:select => "#{table_name}.*, #{distance_sql} distance_in_#{unit}", :order => distance_sql}
      }

      named_scope :within, lambda {|distance, options|
        latitude, longitude = options[:latitude], options[:longitude]
        unit = map_geo_unit(options[:unit])
        distance_sql = Graticule::Distance::Spherical.to_sql(:latitude => latitude, :longitude => longitude, :latitude_column => "#{table_name}.latitude", :longitude_column => "#{table_name}.longitude", :units => unit)
        {:select => "#{table_name}.*, #{distance_sql} distance_in_#{unit}", :conditions => ["#{distance_sql} < ?", distance], :order => distance_sql}
      }
    end
  end
end

ActiveRecord::Base.send :include, Geolocatable
