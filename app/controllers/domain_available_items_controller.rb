class DomainAvailableItemsController < ApplicationController
  required_permissions %w(index add_collection destroy_collection) => "current_user?"
  
  def index
    available_domain_ids = DomainAvailableItem.all(:conditions => {:item_type => params[:item_type], :item_id => params[:item_id]}).map(&:domain_id)
    domains = Domain.all(:conditions => {:account_id => self.current_account.id}, :order => "name")
    result = [{:domain_name => "All", :domain_id => 0, :checked => available_domain_ids.include?(0)}]
    domains.each do |domain|
      result << {:domain_name => domain.name, :domain_id => domain.id, :checked => available_domain_ids.include?(domain.id)}
    end
    respond_to do |format|
      format.json do
        render(:json => {:total => Domain.count(:id, :conditions => {:account_id => self.current_account.id}), 
          :collection => self.assemble_records(result)}.to_json)
      end
    end
  end
    
  def add_collection
    domain_ids = params[:domain_ids].split(",").map(&:to_i)
    domain = nil
    domain_ids.each do |domain_id|
      DomainAvailableItem.create(:item_type => params[:item_type], :item_id => params[:item_id],
        :domain_id => domain_id, :account_id => self.current_account.id)
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => true}.to_json)
      end
    end
  end
    
  def destroy_collection
    if params[:all]
      DomainAvailableItem.delete_all({:item_type => params[:item_type], :item_id => params[:item_id]})
    else
      domain_ids = params[:domain_ids].split(",").map(&:to_i)
      DomainAvailableItem.delete_all({:item_type => params[:item_type], :item_id => params[:item_id], :domain_id => domain_ids})
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => true}.to_json)
      end
    end
  end
  
  protected
  def assemble_records(records)
    out = []
    records.each do |record|
      out << {
        :domain_id => record[:domain_id],
        :domain_name => record[:domain_name],
        :checked => record[:checked]
      }
    end
    out
  end
end
