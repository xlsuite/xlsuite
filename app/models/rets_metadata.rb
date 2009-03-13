#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "ostruct"

class RetsMetadata < ActiveRecord::Base
  validates_presence_of :name, :version, :date
  validates_uniqueness_of :name
  serialize :values

  class << self
    def find_all_resources
      return @all_resources.dup if @all_resources
      @all_resources = returning(Hash.new) do |resources|
        if data = find(:first, :conditions => ["name = ?", "METADATA-RESOURCE"]) then
          data.values.map do |row|
            resources[row["Description"]] = row["ResourceID"]
          end
        end
      end.sort
      @all_resources.dup
    end

    def find_key_name_for_resource(resource)
      raise ArgumentError, "No 'resource' argument to search against" if resource.blank?
      return @key_name_for_resource[resource].dup if @key_name_for_resource && @key_name_for_resource.has_key?(resource)
      meta = find_by_name("METADATA-RESOURCE")
      raise ActiveRecord::RecordNotFound, "Could not find a METADATA-RESOURCE row in the table" unless meta
      data = meta.values.detect {|data| data["ResourceID"] == resource}
      @key_name_for_resource ||= Hash.new
      @key_name_for_resource[resource] = data["KeyField"]
      @key_name_for_resource[resource].dup
    end

    def find_all_classes(resource)
      raise ArgumentError, "No 'resource' argument to search against" if resource.blank?
      return @all_classes[resource].dup if @all_classes && @all_classes.has_key?(resource)
      @all_classes ||= Hash.new
      @all_classes[resource] = returning(Hash.new) do |classes|
        find(:all, :conditions => ["name LIKE ?", "METADATA-CLASS:#{resource}"], :order => "name").map(&:values).map do |data|
          data.map do |row|
            classes[row["Description"]] = row["ClassName"]
          end
        end
      end.sort
      @all_classes[resource].dup
    end

    def find_all_fields(resource, klass)
      raise ArgumentError, "No 'resource' argument to search against" if resource.blank?
      raise ArgumentError, "No 'klass' argument to search against" if klass.blank?
      return @all_fields[[resource, klass]].dup if @all_fields && @all_fields.has_key?([resource, klass])
      @all_fields ||= Hash.new
      @all_fields[[resource, klass]] = returning(Array.new) do |fields|
        if data = find(:first, :conditions => ["name LIKE ?", "METADATA-TABLE:#{resource}:#{klass}"], :order => "name") then
          data.values.map do |data|
            fields << OpenStruct.new(:description => data["LongName"], :value => data["SystemName"],
            :lookup_name => data["LookupName"])
          end
        end
      end.sort_by {|o| (o.description || "").downcase}
      @all_fields[[resource, klass]].dup
    end

    def find_lookup_values(resource, id)
      raise ArgumentError, "No 'resource' argument to search against" if resource.blank?
      raise ArgumentError, "No 'id' argument to search against" if id.blank?
      return @lookup_values[[resource, id]].dup if @lookup_values && @lookup_values.has_key?([resource, id])
      meta = find(:first, :conditions => {:name => "METADATA-LOOKUP_TYPE:#{resource}:#{id}"})
      raise ActiveRecord::RecordNotFound, "Could not find METADATA-LOOKUP_TYPE:#{resource}:#{id}" if meta.blank?
      @lookup_values ||= Hash.new
      @lookup_values[[resource, id]] = returning(Hash.new) do |values|
        meta.values.map do |row|
          values[row["LongValue"]] = row["Value"]
        end
      end.sort
      @lookup_values[[resource, id]].dup
    end
  end
end
