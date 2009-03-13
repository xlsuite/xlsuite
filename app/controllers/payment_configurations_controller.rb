#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentConfigurationsController < ApplicationController
  required_permissions :none

  before_filter :load_source_domains, :only => [:index]
  
  def index
    respond_to do |format|
      format.js
      format.json do
        self.load_payment_configurations
        render(:json => {:collection => self.assemble_records(@payment_configurations), :total => @payment_configurations_count}.to_json)
      end
    end
  end
  
  protected

  def load_payment_configurations
    search_options = {:conditions => "group_name IN ('paypal', 'payment gateway')", :offset => params[:start], :limit => params[:limit], :order => "group_name, name"}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    if params[:domain] && params[:domain].downcase != "all"
      @domain = current_account.domains.find_by_name(params[:domain])
      configurations = current_account.configurations.search(query_params, {:conditions => search_options[:conditions]}).group_by(&:id).values.map do |group|
        group.best_match_for_domain(@domain)
      end.compact.flatten
      sort = params[:sort].blank? ? :group_name : params[:sort].to_sym
      dir = params[:dir] if !params[:dir].blank? && params[:dir] =~ /desc/i
      configurations = configurations.sort_by(&sort)
      configurations.reverse! if dir
      @payment_configurations = configurations[params[:start].to_i, params[:limit].to_i]
      @payment_configurations_count = configurations.size
    else
      @payment_configurations = self.current_account.configurations.search(query_params, search_options)
      @payment_configurations_count = self.current_account.configurations.count_results(query_params, {:conditions => search_options[:conditions]})
    end
  end

  def load_source_domains
    if !params[:domain].blank? then
      @domain = current_account.domains.find_by_name(params[:domain])
    end
    @source_domains = @domain ? [@domain] : current_account.domains.reject {|d| d.name.blank?}
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
      :object_id => record.dom_id,
      :group_name => record.group_name,
      :name => record.name,
      :description => record.description,
      :domain_patterns => record.domain_patterns,
      :value => record.value
    }
  end
  
  def authorized?
    return false unless self.current_user.can?(:edit_configuration)
    self.current_user_is_account_owner?
  end
end
