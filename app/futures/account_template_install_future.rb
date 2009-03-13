#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountTemplateInstallFuture < Future
  def run
    method_callback_future_ids = []
    self.class.transaction do
      method_callback_future_ids = self.account.install_from_account_template!(self.account_template_id)
    end
    self.results[:future_ids] = method_callback_future_ids
    complete!
  end

  def account_template_id
    self.args[:account_template_id]
  end

  def account_template_id=(id)
    self.args ||= Hash.new
    self.args[:account_template_id] = id
  end
end
