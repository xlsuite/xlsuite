#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Timeline < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  belongs_to :subject, :polymorphic => true

  def to_s
    "#{action} #{subject_type}\##{subject_id}"
  end

  def inspect
    "<#{self.class.name} [#{id}]: #{to_s} (#{created_at.to_s(:iso)})>"
  end

  class << self
    def events_between(range, options={})
      returning(self.find(:all, :order => "created_at")) do |events|
        if options[:with_virtual_events] then
          range.step(1.minute) {|timestamp| events << VirtualTimeline.at(timestamp)}
        end
      end.sort_by(&:created_at)
    end
  end
end
