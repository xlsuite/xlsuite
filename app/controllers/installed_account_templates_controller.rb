#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InstalledAccountTemplatesController < ApplicationController
  required_permissions %w(index edit refresh changed_items no_update_items) => "current_user?"
  
  before_filter :load_installed_account_template, :only => %w(edit refresh changed_items no_update_items)
  
  def index
    @installed_account_templates = self.current_account.installed_account_templates
    respond_to do |format|
      format.js
      format.json do
        render :json => {:collection => assemble_records(@installed_account_templates), :total => self.current_account.installed_account_templates.count}.to_json
      end
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def refresh
    @refreshed = @installed_account_template.update_from_account_template!(params[:update])
    respond_to do |format|
      format.js do
        render :json => {:success => @refreshed}.to_json
      end
    end
  end
  
  def changed_items
    @changed_items = @installed_account_template.compare_with(current_account)
    respond_to do |format|
      format.json do
        json_records = []
        @changed_items.each do |changed_item|
          json_records << {
            :include => true,
            :id => changed_item.dom_id,
            :type => changed_item.class.name,
            :identifier => case changed_item
                           when Layout
                             changed_item.title
                           when Snippet
                             changed_item.title
                           when Page
                             "#{changed_item.title} | #{changed_item.fullslug.inspect}"
                           end,
            :domain_patterns => (changed_item.respond_to?(:domain_patterns) ? changed_item.domain_patterns : ""),
            :updated_at => (changed_item.respond_to?(:updated_at) ? changed_item.updated_at.strftime('%b %d, %Y %I:%M %p') : "")
          }
        end
        render :json => {:collection => json_records, :total => json_records.size}.to_json 
      end
    end
  end
  
  def no_update_items
    @no_update_items = @installed_account_template.list_no_update_items_with(self.current_account)
    respond_to do |format|
      format.json do
        json_records = []
        @no_update_items.each do |changed_item|
          json_records << {
            :include => true,
            :id => changed_item.dom_id,
            :type => changed_item.class.name,
            :identifier => case changed_item
                           when Layout
                             changed_item.title
                           when Snippet
                             changed_item.title
                           when Page
                             "#{changed_item.title} | #{changed_item.fullslug.inspect}"
                           end,
            :domain_patterns => (changed_item.respond_to?(:domain_patterns) ? changed_item.domain_patterns : ""),
            :updated_at => (changed_item.respond_to?(:updated_at) ? changed_item.updated_at.strftime('%b %d, %Y %I:%M %p') : "")
          }
        end
        render :json => {:collection => json_records, :total => json_records.size}.to_json 
      end
    end
  end
  
  protected
  
  def load_installed_account_template
    @installed_account_template = self.current_account.installed_account_templates.find(params[:id])
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
      :name => record.account_template.name,
      :domain_patterns => record.domain_patterns,
      :updated_at => record.updated_at.to_s, 
      :installed_at => record.created_at.to_s
    }
  end

  def authorized
    return false unless self.current_user.id == self.current_account.owner.id
    true
  end
end
