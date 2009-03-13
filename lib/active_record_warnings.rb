#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ActiveRecord
  class Warnings
    include Enumerable

    def initialize(base) # :nodoc:
      @base, @warnings = base, {}
    end

    @@default_warning_messages = {
      :inclusion => "is not included in the list",
      :exclusion => "is reserved",
      :invalid => "is invalid",
      :confirmation => "doesn't match confirmation",
      :accepted  => "must be accepted",
      :empty => "can't be empty",
      :blank => "can't be blank",
      :too_long => "is too long (maximum is %d characters)",
      :too_short => "is too short (minimum is %d characters)",
      :wrong_length => "is the wrong length (should be %d characters)",
      :taken => "has already been taken",
      :not_a_number => "is not a number"
    }

    # Holds a hash with all the default warning messages, such that they can be replaced by your own copy or localizations.
    cattr_accessor :default_warning_messages


    # Adds an warning to the base object instead of any particular attribute. This is used
    # to report warnings that don't tie to any specific attribute, but rather to the object
    # as a whole. These warning messages don't get prepended with any field name when iterating
    # with each_full, so they should be complete sentences.
    def add_to_base(msg)
      add(:base, msg)
    end

    # Adds an warning message (+msg+) to the +attribute+, which will be returned on a call to <tt>on(attribute)</tt>
    # for the same attribute and ensure that this warning object returns false when asked if <tt>empty?</tt>. More than one
    # warning can be added to the same +attribute+ in which case an array will be returned on a call to <tt>on(attribute)</tt>.
    # If no +msg+ is supplied, "invalid" is assumed.
    def add(attribute, msg = @@default_warning_messages[:invalid])
      @warnings[attribute.to_s] = [] if @warnings[attribute.to_s].nil?
      @warnings[attribute.to_s] << msg
    end

    # Will add an warning message to each of the attributes in +attributes+ that is empty.
    def add_on_empty(attributes, msg = @@default_warning_messages[:empty])
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        is_empty = value.respond_to?("empty?") ? value.empty? : false
        add(attr, msg) unless !value.nil? && !is_empty
      end
    end

    # Will add an warning message to each of the attributes in +attributes+ that is blank (using Object#blank?).
    def add_on_blank(attributes, msg = @@default_warning_messages[:blank])
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        add(attr, msg) if value.blank?
      end
    end

    # Will add an warning message to each of the attributes in +attributes+ that has a length outside of the passed boundary +range+.
    # If the length is above the boundary, the too_long_msg message will be used. If below, the too_short_msg.
    def add_on_boundary_breaking(attributes, range, too_long_msg = @@default_warning_messages[:too_long], too_short_msg = @@default_warning_messages[:too_short])
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        add(attr, too_short_msg % range.begin) if value && value.length < range.begin
        add(attr, too_long_msg % range.end) if value && value.length > range.end
      end
    end

    alias :add_on_boundry_breaking :add_on_boundary_breaking
    deprecate :add_on_boundary_breaking => :validates_length_of, :add_on_boundry_breaking => :validates_length_of

    # Returns true if the specified +attribute+ has warnings associated with it.
    def invalid?(attribute)
      !@warnings[attribute.to_s].nil?
    end

    # * Returns nil, if no warnings are associated with the specified +attribute+.
    # * Returns the warning message, if one warning is associated with the specified +attribute+.
    # * Returns an array of warning messages, if more than one warning is associated with the specified +attribute+.
    def on(attribute)
      warnings = @warnings[attribute.to_s]
      return nil if warnings.nil?
      warnings.size == 1 ? warnings.first : warnings
    end

    alias :[] :on

    # Returns warnings assigned to base object through add_to_base according to the normal rules of on(attribute).
    def on_base
      on(:base)
    end

    # Yields each attribute and associated message per warning added.
    def each
      @warnings.each_key { |attr| @warnings[attr].each { |msg| yield attr, msg } }
    end

    # Yields each full warning message added. So Person.warnings.add("first_name", "can't be empty") will be returned
    # through iteration as "First name can't be empty".
    def each_full
      full_messages.each { |msg| yield msg }
    end

    # Returns all the full warning messages in an array.
    def full_messages
      full_messages = []

      @warnings.each_key do |attr|
        @warnings[attr].each do |msg|
          next if msg.nil?

          if attr == "base"
            full_messages << msg
          else
            full_messages << @base.class.human_attribute_name(attr) + " " + msg
          end
        end
      end
      full_messages
    end

    # Returns true if no warnings have been added.
    def empty?
      @warnings.empty?
    end
    
    # Removes all the warnings that have been added.
    def clear
      @warnings = {}
    end

    # Returns the total number of warnings added. Two warnings added to the same attribute will be counted as such
    # with this as well.
    def size
      @warnings.values.inject(0) { |warning_count, attribute| warning_count + attribute.size }
    end
    
    alias_method :count, :size
    alias_method :length, :size

    # Return an XML representation of this warning object.
    def to_xml(options={})
      options[:root] ||= "warnings"
      options[:indent] ||= 2
      options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

      options[:builder].instruct! unless options.delete(:skip_instruct)
      options[:builder].warnings do |e|
        full_messages.each { |msg| e.warning(msg) }
      end
    end
  end

  module WarningMessages 
    def self.included(base)
      base.send :include, InstanceMethods  
    end

    module InstanceMethods
      def warnings
        @warnings ||= ActiveRecord::Warnings.new(self)
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::WarningMessages)
