#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Step < ActiveRecord::Base
  VALID_OBJECT_TYPES = %w(Blog BlogPost Comment Party).freeze
  
  belongs_to :account
  validates_presence_of :account_id
  before_validation {|s| s.account = s.workflow.account if s.workflow}

  belongs_to :workflow

  acts_as_list :scope => :workflow

  has_many :tasks, :order => "position", :dependent => :destroy

  validates_presence_of :model_class_name

  before_create :generate_random_uuid

  serialize :lines, Array
  def lines=(ls)
    ls = ls.to_a.sort_by {|e| e.first.to_i}.map(&:last) if ls.kind_of?(Hash)
    
    ls.collect! do |line|
      next line if line.kind_of?(ReportLine)
      ReportLine.using(line.delete("operator")).new(line)
    end if ls

    write_attribute(:lines, ls)
  end

  def lines
    read_attribute(:lines) || self.lines = Array.new
  end
  
  def add_line(ls)
    ls = ls.stringify_keys!
    write_attribute(:lines, self.lines << ReportLine.using(ls.delete("operator")).new(ls))
  end
  
  def update_line(position, ls)
    ls = ls.stringify_keys!
    self.lines[position.to_i] = ReportLine.using(ls.delete("operator")).new(ls)
  end
  
  def destroy_line(position)
    self.lines.delete_at(position.to_i)
  end

  def model_class=(klass)
    self.model_class_name = klass.name
  end

  def model_class
    self.model_class_name.constantize
  end

  def models
    model_class.run_report(self.account, self.lines.dup).uniq
  end

  def run
    data = self.models
    self.tasks.each do |task|
      task.run(data)
    end
  end

  def run!
    self.class.transaction do
      self.run
      self.update_attribute(:last_run_at, Time.now.utc)
    end
  end

  def attributes_for_copy_to(account)
    attributes = self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :activated_at => nil, :position => nil)
    attributes.delete(:workflow_id)
    attributes
  end

  def copy_to_target_in_account(target, account, options={})
    target.attributes = self.attributes_for_copy_to(account)
    target.save!
    self.tasks.each do |task|
      new_task = target.tasks.build()
      task.copy_to_target(new_task, account, options)
    end
  end

  class << self
    def find_next_runnable_steps
      find(:all, :conditions => ["activated_at <= NOW() AND (disabled_at IS NULL OR disabled_at > NOW()) AND (`interval` < TIMESTAMPDIFF(SECOND, last_run_at, NOW()))"])
    end
  end
end
