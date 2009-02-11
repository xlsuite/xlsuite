#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../config/environment"
require "yaml"
require "erb"

def logger
  RAILS_DEFAULT_LOGGER
end

def remove_duplicates(futures)
  return futures if futures.size <= 1
  futures_clone = Marshal::load(Marshal.dump(futures))
  for i in 0..futures.size-1
    next if futures[i].nil?
    for j in i+1..futures.size
      next if futures[j].nil?
      if futures[i] == futures[j]
        futures_clone[j] = nil
      end
    end
  end
  futures_clone.compact
end

conditions = ["started_at IS NULL", "futures.interval IS NOT NULL"]
futures_to_delete = Future.find(:all, :conditions => conditions)
futures = YAML.load(ERB.new(File.read(RAILS_ROOT + "/config/futures.yml")).result)

Future.transaction do
  futures.each_pair do |future_type, attrs|
    account_id = attrs["account_id"]
    conds = conditions.dup
    conds << "account_id = '#{Future.quote_value(account_id)}'" if account_id

    account_futures = future_type.constantize.find(:all, :conditions => conds.join(" AND "))

    instantiate_future = true

    # go create the future if it doesn't already exist for this account_id
    unless account_futures.blank?
      account_futures = remove_duplicates(account_futures)

      account_futures.each do |account_future|
        if account_future == future_type.constantize.new(attrs)
          # don't destroy this future later, and don't create a new future of this type
          futures_to_delete.delete_if {|f| f.id == account_future.id }
          instantiate_future = false
        else
          # make sure future will be destroyed
          futures_to_delete << account_future
        end
      end
    end

    if instantiate_future
      logger.info "Creating a new #{future_type} future..."
      future_type.constantize.create!(attrs)
      logger.info "#{future_type} created"
    end
  end

  unless futures_to_delete.blank?
    logger.info "Deleting futures: #{futures_to_delete.collect{|f| "ID: #{f.id}, Type: #{f.class}"}.inspect}"
    Future.delete_all(["id in (?)", futures_to_delete.map(&:id).uniq])
  end
end
