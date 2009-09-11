#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class GroupDrop < Liquid::Drop
  attr_reader :group
  delegate :name, :id, :parent_id, :avatar, :private?, :products, :group_items, :label, :tag_list, :to => :group

  def initialize(group)
    @group = group
  end
  
  def children
    self.group.children.map(&:to_liquid)
  end
  
  def user_member_of
    return false unless self.context && self.context["user"] && self.context["user"].party
    self.context["user"].party.member_of?(self.group)
  end
  
  def profile_member_of
    return false unless self.context && self.context.scopes.last["profile"] && self.context.scopes.last["profile"].party
    self.context.scopes.last["profile"].party.member_of?(self.group)
  end
  
  def description
    template = Liquid::Template.parse(self.group.description)
    template.render(context)
  end
  
  def web_copy
    template = Liquid::Template.parse(self.group.web_copy)
    template.render(context)
  end
  
  def private_description
    return "" unless self.group.private?
    template = Liquid::Template.parse(self.group.private_description)
    template.render(context)
  end
end
