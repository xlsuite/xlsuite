#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailLabelsController < ApplicationController
  required_permissions %w(new show index create update destroy destroy_collection) => "current_user?"
  
  before_filter :load_label, :only => %w(update destroy)
  
  def index
    case params[:dir]
    when "ASC", "DESC"
      sort_dir = params[:dir]
    else
      sort_dir = "ASC"
    end
    @labels = current_user.email_labels.find(:all, :order => ("name " + sort_dir))
    respond_to do |format|
      format.js
      format.json do
        wrapper = { 'total' => @labels.size, 'collection' => truncate_records(@labels)[params[:start].to_i, params[:limit].to_i] }
        render :json => wrapper.to_json
      end
    end
  end
  
  def show
    @labels = current_user.email_labels.find(:all, :order => "name ASC")
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def new
    
  end
  
  def create
    @label = current_user.email_labels.build(params[:email_label])
    @label.account = current_account
    @created = @label.save
    if @created
      flash_success :now, "Email label #{@label.name} successfully created"
    else
      flash_failure :now, @label.errors.full_messages
    end  
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @updated = @label.update_attributes(params[:email_label])
    if @updated
      flash_success :now, "Email label #{@label.name} successfully updated"
    else
      flash_failure :now, @label.errors.full_messages
    end  
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @label.filters.each {|filter| filter.email_label=nil}
    if @label.destroy
      render :update do |page|
        page << "parent.$('status-bar-notifications').innerHTML = 'Label destroyed';"
        page.visual_effect :highlight, 'email_label_'+@label.id.to_s+'_row', :duration => 1.5
        page.delay(1) do
          page.remove 'email_label_'+@label.id.to_s+'_row'
        end
        page << "parent.myEmailLabelsRefresh();"
      end
    else
      redirect_to email_labels_path
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.email_labels.find(params[:ids].split(",").map(&:strip)).to_a.each do |label|
      @destroyed_items_size += 1 if label.destroy
    end
    
    flash_success :now, "#{@destroyed_items_size} label(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
protected
  def load_label
    @label = current_user.email_labels.find(params[:id])
  end
  
  def truncate_records(labels)
    truncated_records = []
    labels.each do |label|  
      truncated_record = {
        'id' => label.id,
        'name' => label.name
      }
      truncated_records.push truncated_record
    end
    return truncated_records
  end
end
