#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module JsonCollectionBuilder
  def self.build(collection, total_size=-1)
    total = total_size == -1 ? collection.size : total_size
    json_collection = case collection.first 
      when ActiveRecord::Base
        collection.map(&:to_json).join(',')
      when String
        collection.join(',')
      end
    %Q!{'total':#{total}, 'collection':[#{json_collection}]}!
  end
  
  def self.build_from_objects(collection, total_size=-1)
    total = total_size == -1 ? collection.size : total_size
    json_collection = []
    counter = 0
    collection.each do |e|
      counter = counter + 1
      hash = self.to_hash(e).merge("id" => counter)
      hash.stringify_keys!
      json_collection << hash.inspect.gsub("=>", ":")
    end
    %Q!{'total':#{total}, 'collection':[#{json_collection.join(',')}]}!
  end
  
  protected
  def self.to_hash(object)
    attributes = {}
    hash = {}
    object.attributes.keys.each do |attr_name|
      next if attr_name == "id"
      attributes.merge!(attr_name => object.send(attr_name))
    end
    id = object.class.name.downcase + "_" + object.id.to_s
    hash.merge!("object_id" => id)
    attributes.each_pair do |key,value|
      next if value.blank?
      hash.merge!(key.to_s => JavascriptEscaper::escape(value.to_s)) unless %w(account_id id).index(key.to_s)
    end
    hash
  end
end
