#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FiltersController < ApplicationController
  include FiltersHelper
 
  required_permissions %w(index new update create edit destroy empty_grid test_data) => "current_user?"
  before_filter :load_filter, :only => %w(update destroy)
  before_filter :filter_query, :only => %w(update create test_data)
 
  def index
    @filters = current_user.filters.find(:all)
  end
  
  def new
    @filter = Filter.new
    @filter.email_label = EmailLabel.new
  end
  
  def empty_grid
    @emails = []
    respond_to do |format|
      format.json do
        render(:text => JsonCollectionBuilder::build(@emails, 0))
      end
    end
  end
  
  def test_data
    @emails = truncate_records(@emails)
    start = params[:start].to_i
    limit = params[:limit].to_i
    respond_to do |format|
      format.json do
        wrapper = { 'total' => @emails.size, 'collection' => @emails[start, limit] }
       
        render :json => wrapper.to_json
      end
    end
  end
  
  def update
    if params[:_test]
      respond_to do |format|
        format.js
      end
    elsif params[:_update_]
      @filter.name = params[:filter][:name]
      @filter.description = params[:filter][:description]
      @filter.email_label_id = params[:filter][:email_label_id]
      Filter.transaction do
        process_filter_lines
        @filter.emails = @emails
        @filter.save!
        
        flash_success "Filter successfully updated"
        redirect_to(filters_path)
      end
    end
    rescue
      render :action => :edit  
  end
  
  def create
    if params[:_test]
      respond_to do |format|
        format.js {render :action => :update}
      end
    elsif params[:_save] 
      @filter = current_account.filters.build(params[:filter])
      @filter.party = current_user
      Filter.transaction do
        process_filter_lines
        @filter.emails = @emails
        
        @filter.save!
        flash_success "Filter created"
        redirect_to(filters_path)
      end
    end
    rescue
      render :action => :new  
  end
  
  def edit
    @filter = current_user.filters.find(params[:id])
  end
  
  def destroy
    if @filter.destroy
      render :update do |page|
        page << "parent.$('status-bar-notifications').innerHTML = 'Filter destroyed';"
        page.visual_effect :highlight, 'filter_'+@filter.id.to_s+'_row', :duration => 1.5
        page.delay(1) do
          page.remove 'filter_'+@filter.id.to_s+'_row'
        end
      end
    else
      redirect_to filters_path
    end
  end
  
protected
  def process_filter_lines
    @filter.filter_lines.clear
    filter_params = []
    for i in 1..params[:num_of_filter_line].to_i
      filter_params << params[:filter_line]["#{i}"] if params[:filter_line].has_key?("#{i}")
    end
    for i in 1..filter_params.size
      filter_line = FilterLine.new()
      filter_line.field = filter_params[i-1]["field"]
      filter_line.operator = filter_params[i-1]["operator"]
      filter_line.value = filter_params[i-1]["value"]
      filter_line.exclude = filter_params[i-1]["exclude"]=='1' ? true : false
      @filter.filter_lines << filter_line if filter_line.save!
    end
  end
  
  def load_filter
    @filter = current_user.filters.find(params[:id])
  end
  
  def filter_query
    filter_params = []
    conditions = ""
    joins = ""
    conditions_hash = {}
    for i in 1..params[:num_of_filter_line].to_i
      filter_params << params[:filter_line]["#{i}"] if params[:filter_line].has_key?("#{i}")
    end
    for i in 1..filter_params.size
      filter_line = deep_clone(filter_params[i-1])
      conditions << " AND " if i>1
      case filter_line["field"]
        when "from"
          joins << " INNER JOIN recipients AS sender#{i-1} ON emails.id = sender#{i-1}.email_id"
          conditions << "sender#{i-1}.type = 'Sender' AND sender#{i-1}.address "
        when "to"
          joins << " INNER JOIN recipients AS to_recip#{i-1} ON emails.id = to_recip#{i-1}.email_id"
          conditions << "to_recip#{i-1}.type = 'ToRecipient' AND to_recip#{i-1}.address "
        when "subject"
          conditions << "subject "
        when "body"
          conditions << "body "
      end
      conditions << "NOT " if filter_line["exclude"] == '1'
      conditions << "LIKE :value#{i-1}"
      #create conditions_hash
      if filter_line["operator"] =~ /^contain$|^end$/
        filter_line["value"] = '%' << filter_line["value"]
      end
      if filter_line["operator"] =~ /^contain$|^start$/
        filter_line["value"] = filter_line["value"] << '%'
      end
      conditions_hash["value#{i-1}".to_sym] = filter_line["value"]
    end
    @emails = current_user.emails.find(:all, :select => "DISTINCT emails.*",
        :joins => joins, 
        :conditions => [conditions, conditions_hash])
    @emails.uniq!
  end
  
  def truncate_records(emails)
    truncated_records = []
    emails.each do |email|  
      # email is the full set of data, but we only want
      # id, subject, received_at, created_at, sender.id, sender.name
      to_names = email.tos.collect { |sender| sender.name }
      truncated_record = {
        'id' => email.id,
        'subject' => email.subject,
        'received_at' => email.received_at.to_s,
        'created_at' => email.created_at.to_s,
        'released_at' => email.released_at.to_s,
        'updated_at' => email.updated_at.to_s,
        'scheduled_at' => email.scheduled_at.to_s,
        'sent_at' => email.sent_at.to_s,
        'sender_id' => email.sender.id,
        'sender_name' => email.sender.name,
        'sender_address' => email.sender.address,
        'party_id' => email.sender.party_id,
        'body' => email.body,
        'to_names' => to_names.class == Array ? to_names.join(', ') : to_names
      }
      truncated_records.push truncated_record
    end
    return truncated_records
  end
  
  def deep_clone(params)
    Marshal::load(Marshal.dump(params))
  end
end
