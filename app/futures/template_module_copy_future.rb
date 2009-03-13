#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TemplateModuleCopyFuture < Future
  def run
    self.class.transaction do
      self.account.template_name = self.template_name
      self.account.selected_modules = self.selected_modules
      self.account.copy_template_and_modules!
      page = self.account.pages.find(:first)
      page.save! if page
    end

    complete!
  end

  def template_name
    self.args[:template_name]
  end

  def template_name=(name)
    self.args ||= Hash.new
    self.args[:template_name] = name
  end

  def selected_modules
    self.args[:selected_modules]
  end

  def selected_modules=(names)
    self.args ||= Hash.new
    self.args[:selected_modules] = names
  end
end
