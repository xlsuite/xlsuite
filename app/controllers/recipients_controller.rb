#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RecipientsController < ApplicationController
  required_permissions %w(index destroy_collection rebuild) => "current_user?"
  
  before_filter :load_email
  
  def index
    respond_to do |format|
      format.js do
        params[:id] = params[:email_id]
      end
      format.json do
        search_options = {:offset => params[:start], :limit => params[:limit], :order => "name ASC"}
        search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    
        query_params = params[:q]
        unless query_params.blank?
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
    
        @recipients = @email.mass_recipients.search(query_params, search_options)
        @recipients_count = @email.mass_recipients.count_results(query_params, {:conditions => "recipients.id > 0"})
        
        render :json => {:collection => assemble_records(@recipients), :total => @recipients_count}.to_json
      end
    end
  end
  
  def rebuild
    @future = MethodCallbackFuture.create!(:models => [@email], :account =>  @email.account, :owner => current_user,
          :method => :generate_mass_recipients, :result_url => email_recipients_path(@email))
    respond_to do |format|
      format.js
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    @email.mass_recipients.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |mass_recip|
      if mass_recip.party
        current_account.groups.find(params[:gids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |group|
          mass_recip.party.groups.delete(group) if mass_recip.party.member_of?(group)
        end
        
        tag_list = mass_recip.party.tag_list
        tag_list = tag_list.split(",").map(&:strip).reject(&:blank?).delete_if{|t|!params[:tags].split(",").map(&:strip).reject(&:blank?).index(t).blank?}
        mass_recip.party.tag_list = tag_list
        
        mass_recip.party.update_effective_permissions = true
        mass_recip.party.save
      end
      
      if mass_recip.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end
    
    
    
    error_message = []
    error_message << "#{@destroyed_items_size} recipients(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} recipients(s) failed to be destroyed" if @undestroyed_items_size > 0
    
    flash_success :now, error_message.join(", ") 
    respond_to do |format|
      format.js
    end
  end
  
protected
  def load_email
    @email = current_account.emails.find(params[:email_id])
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end

  def truncate_record(record)
    {
      :id => record.id,
      :name => record.name,
      :address => record.address
    }
  end
end
