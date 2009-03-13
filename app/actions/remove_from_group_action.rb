#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RemoveFromGroupAction < Action
  attr_accessor :group_id

  def run_against(*args)
    options = args.last.kind_of?(Hash) ? args.pop : Hash.new
    models = args.flatten.compact
    models.flatten.compact.each do |model|
      model.groups.delete(self.group) if model.member_of?(self.group)
    end
  end

  def description
    "Remove from group labelled #{self.group ? self.group.label : ''}"
  end
  
  def group
    @group ||= (self.group_id ? Group.find(self.group_id) : nil rescue nil)
  end
    
  def duplicate(account, options={})
    action = self.class.new
    if self.group
      target_group = account.groups.find_by_label(self.group.label)
      if options[:create_dependencies]
        target_group ||= account.groups.create!(self.group.attributes_for_copy_to(account))
      end
    end
    action.group_id = target_group.id if target_group
    action
  end

  class << self
    def parameters
      [
        {
          :group => {
            :type => :groups,
            :field => "selection", 
            :store => "current_account.groups.find(:all).map{|g| [g.label, g.id]}"
          }
        }
      ]
    end
  end

end
