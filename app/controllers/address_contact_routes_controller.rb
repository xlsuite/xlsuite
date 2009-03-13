#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AddressContactRoutesController < ApplicationController
  before_filter :load_routable
  before_filter :load_address, :except => %w(index new create create_new destroy_collection)
  required_permissions %w(index new edit) => true, %w(show create create_new update update_new destroy destroy_collection) => [:edit_party, :edit_own_account, 
    :edit_own_contacts_only, {:any => true}]

  helper :contact_routes
  
  def index
    respond_to do |format|
      format.json do
        @addresses = @routable.addresses
        @addresses_count = @routable.addresses.count
        render :json => {:collection => self.assemble_records(@addresses), :total => @addresses_count}.to_json
      end
    end
  end

  def new
    @address = AddressContactRoute.new(:routable => @routable)
    show
  end

  def show
    render :partial => "address_contact_route", :object => @address, :layout => false
  end

  def create
    @address = @routable.addresses.build(params[:address].values.first)
    if @address.save then
      respond_to do |format|
        format.js { render :action => "create" }
      end
    else
      raise "Do something !"
    end
  end
  
  def create_new
    @address = @routable.addresses.build(params[:address])
    @created = @address.save
    if @created then
      messages = "New address successfully created"
    else
      messages = render_error_messages_for(:address)
    end
    respond_to do |format|
      format.js do
        render :json => {:success => @created, :messages => messages}.to_json
      end
    end
  end

  def update
    if @address.update_attributes(params[:address][params[:id]]) then
      respond_to do |format|
        format.js { render :action => "update" }
      end
    else
      raise "Do something !"
    end
  end
  
  def update_new
    @address.attributes = params[:address]
    @updated = @address.save
    respond_to do |format|
      format.js do
        response = assemble_record(@address.reload)
        if !@updated
          response.merge!(:flash => "Error:")
        end
        render :json => response.to_json
      end
    end
  end

  def destroy
    if @address.destroy then
      respond_to do |format|
        format.js { render :action => "destroy" }
      end
    else
      raise "Do something !"
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    @routable.addresses.find(params[:ids].split(",").map(&:strip)).each do |address|
      if address.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    messages = []
    messages << "#{@destroyed_items_size} address(es) successfully deleted" if @destroyed_items_size > 0
    messages << "#{@undestroyed_items_size} address(es) failed to be destroyed" if @undestroyed_items_size > 0

    respond_to do |format|
      format.js do
        render :json => {:messages => render_messages_as_ul(messages)}.to_json
      end
    end
  end

  protected
  def load_routable
    @routable = nil
    @routable = current_account.parties.find_by_id(params[:party_id]) if params[:party_id]
    @routable = current_account.profiles.find_by_id(params[:profile_id]) if params[:profile_id]
  end

  def load_address
    addr_route = AddressContactRoute.find(params[:id])
    @address = if current_user.can?(:edit_party) then
      if @routable then
        @routable.addresses.find(params[:id])
      else
        addr_route
      end
    elsif current_user.can?(:edit_own_contacts_only) && addr_route.routable != current_user then
      if @routable && @routable.created_by_id == current_user.id
        @routable.addresses.find(params[:id])
      else
        addr_route if addr_route.routable_type = "Party" && addr_route.routable.created_by_id == current_user.id
      end
    elsif current_user.can?(:edit_own_account) then
      current_user.addresses.find(params[:id])
    else
      authorization_failure!("You are not authorized to edit this address")
    end
  end
  
  def assemble_records(records)
    out = []
    records.each do |record|
      out << assemble_record(record)
    end
    out
  end
  
  def assemble_record(record)
    {
      :id => record.id,
      :name => record.name.to_s,
      :line1 => record.line1.to_s,
      :line2 => record.line2.to_s,
      :line3 => record.line3.to_s,
      :city => record.city.to_s,
      :state => record.state.to_s,
      :zip => record.zip.to_s,
      :country => record.country.to_s,
      :latitude => record.latitude,
      :longitude => record.longitude
    }
  end
end
