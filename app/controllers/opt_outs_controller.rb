#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class OptOutsController < ApplicationController
  skip_before_filter :login_required
  verify :method => :post, :only => :unsubscribe,
      :render => {:status => "406 Method Not Allowed", :text => "<h1>Method Not Allowed</h1>"}
  verify :method => :get, :only => %w(show unsubscribed),
      :render => {:status => "406 Method Not Allowed", :text => "<h1>Method Not Allowed</h1>"}
  before_filter :load_recipient, :only => %w(show unsubscribe)

  def show
    @title = "Unsubscribe"
    render_within_public_layout
  end

  def unsubscribe
    account = @recipient.party.account
    unless params[:tags].blank? then
      # We aren't looking at current_account here because we might
      # have sent this mail from another account:  mail to account owners,
      # for instance.  In that case, we must search the party's account,
      # and not current_account, which might not even contain the tag(s)
      # we're going to remove here.
      @tags = account.tags.find_all_by_name(Tag.parse(params[:tags]))
      @tags.each do |tag|
        @recipient.party.tags.delete(tag)
      end
    end
    
    unless params[:groups].blank? then
      params[:groups].reject(&:blank?).each do |g_id|
        group = account.groups.find(g_id)
        @recipient.party.groups.delete(group) if group && @recipient.party.member_of?(group)
      end
    end
    
    unless params[:action_handlers].blank? then
      params[:action_handlers].reject(&:blank?).each do |a_id|
        action_handler = self.current_account.action_handlers.find(a_id)
        action_handler.destroy_membership_on_domain(@recipient.party, self.current_domain)
      end
    end
    
    logger.debug {"==> return_to_url: #{@recipient.return_to_url}\n#{request.env.to_yaml}"}
    redirect_to @recipient.email.return_to_url
  end

  def unsubscribed
    @title = "Unsubscribed"
    render_within_public_layout
  end

  protected
  def load_recipient
    uuid = params[:uuid] || params[:id]
    raise ActiveRecord::RecordNotFound if uuid.blank?
    @recipient = Recipient.find_by_uuid!(uuid)
  end
end
