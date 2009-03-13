#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ConfigurationsController < ApplicationController
  required_permissions :edit_configuration

  before_filter :load_configuration, :only => [:new, :edit, :update]

  before_filter :load_source_domains, :only => [:index]

  def index
    respond_to do |format|
      format.html do
        @configurations = current_account.configurations.find(:all, :order => "group_name, name")
        @product_categories = current_account.product_categories.roots
        @parties = current_account.parties.for_select
      end
      format.js
      format.json do
        self.load_configurations
        render(:json => {:total => @configurations_count, :collection => assemble_records(@configurations)}.to_json)
      end
    end
  end

  def new
    @old_configuration = @configuration
    @configuration = @old_configuration.class.new(@old_configuration.attributes)
    @configuration.set_value(@old_configuration.value)
    respond_to do |format|
      format.js
    end
  end

  def create
    respond_to do |format|
      format.html do
        params[:config].each do |id, values|
          config = current_account.configurations.find(id)
          config.set_value!(values[:value])
        end

        flash_success "Configurations successfully updated"
        redirect_to :action => 'index'
      end
      format.js do
        @old_configuration = current_account.configurations.find(params[:id])
        @configuration = @old_configuration.class.new(@old_configuration.attributes)
        @configuration.attributes = params[:configuration]
        @configuration.set_value(params[:configuration][:value])
        @created = @configuration.save
        flash_success :now, "New #{@configuration.name} configuration successfully created" if @created
        @close = true
      end
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @configuration.attributes = params[:configuration]
    @configuration.set_value(params[:configuration][:value])
    @updated = @configuration.save
    flash_success :now, "Configuration #{@configuration.name} updated successfully" if @updated
    respond_to do |format|
      format.js do
        render :json => {:success => true, :flash => flash[:notice].to_s}.to_json
      end
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.configurations.find(params[:ids].split(",").map(&:strip)).to_a.each do |configuration|
      if configuration.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} configuration(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} configuration(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end

  protected
  def load_configuration
    @configuration = current_account.configurations.find(params[:id])
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

  def load_configurations
    search_options = {:conditions => "group_name NOT IN ('paypal', 'payment gateway')", :offset => params[:start], :limit => params[:limit], :order => "group_name, name"}
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
      @configurations = configurations[params[:start].to_i, params[:limit].to_i]
      @configurations_count = configurations.size
    else
      @configurations = current_account.configurations.search(query_params, search_options)
      @configurations_count = current_account.configurations.count_results(query_params, {:conditions => search_options[:conditions]})
    end
  end
end
