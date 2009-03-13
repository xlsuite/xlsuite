#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailContactRoutesController < ApplicationController
  before_filter :load_routable
  before_filter :load_email, :except => %w(index new create validate create_new destroy_collection)
  required_permissions %w(index new edit) => true,
      %w(show create create_new update update_new destroy destroy_collection validate) => [:edit_party, :edit_own_account, 
        :edit_own_contacts_only, {:any => true}]

  helper :contact_routes

  def index
    respond_to do |format|
      format.json do
        @email_addresses = @routable.email_addresses
        @email_addresses_count = @routable.email_addresses.count
        render :json => {:collection => self.assemble_records(@email_addresses), :total => @email_addresses_count}.to_json
      end
    end
  end
  
  def new
    @email_address = EmailContactRoute.new(:routable => @routable)
    show
  end

  def show
    render :partial => "email_contact_route", :object => @email_address, :layout => false
  end

  def validate
    @route = EmailContactRoute.find(params[:id]) unless params[:id].blank?
    @route = EmailContactRoute.new(:routable_type => "Party") unless @route
    @route.attributes = params[:email]
    @route.account = current_account

    @route.valid? # Trigger validation
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def create
    @email_address = @routable.email_addresses.build(params[:email_address].values.first)
    if @email_address.save then
      respond_to do |format|
        format.js { render :action => "create" }
        format.html { redirect_to party_path(@email_address.routable) }
      end
    else
      respond_to do |format|
        format.js { render :action => "error" }
      end
    end
  end
  
  def create_new
    @email_address = @routable.email_addresses.build(params[:email])
    @created = @email_address.save
    if @created then
      messages = "New email address successfully created"
    else
      messages = render_error_messages_for(:email_address)
    end
    respond_to do |format|
      format.js do
        render :json => {:success => @created, :messages => messages}.to_json
      end
    end
  end

  def update
    attrs = params[:email_address][params[:id]]
    if attrs && attrs.has_key?(:email_address) && attrs[:email_address].blank? then
      destroy # We destroy if the user resets the address field to the empty string
    elsif @email_address.update_attributes(attrs) then
      respond_to do |format|
        format.js { render :action => "update" }
        format.html { redirect_to party_path(@email_address.routable) }
      end
    else
      respond_to do |format|
        format.js { render :action => "error" }
      end
    end
  end
  
  def update_new
    @email_address.attributes = params[:email]
    @updated = @email_address.save
    respond_to do |format|
      format.js do
        response = assemble_record(@email_address.reload)
        if !@updated
          response.merge!(:flash => "Error:")
        end
        render :json => response.to_json
      end
    end
  end

  def destroy
    if @email_address.destroy then
      respond_to do |format|
        format.js { render :action => "destroy" }
        format.html { redirect_to party_path(@routable) }
      end
    else
      raise "Do something !"
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    @routable.email_addresses.find(params[:ids].split(",").map(&:strip)).each do |address|
      if address.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    messages = []
    messages << "#{@destroyed_items_size} email_address(es) successfully deleted" if @destroyed_items_size > 0
    messages << "#{@undestroyed_items_size} email_address(es) failed to be destroyed" if @undestroyed_items_size > 0

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

  def load_email
    email_route = EmailContactRoute.find(params[:id])
    @email_address = if current_user.can?(:edit_party) then
      if @routable then
        @routable.email_addresses.find(params[:id])
      else
        email_route
      end
    elsif current_user.can?(:edit_own_contacts_only) && email_route.routable != current_user then
      if @routable && @routable.created_by_id == current_user.id
        @routable.email_addresses.find(params[:id])
      else
        email_route if email_route.routable_type = "Party" && email_route.routable.created_by_id == current_user.id
      end
    elsif current_user.can?(:edit_own_account) then
      current_user.email_addresses.find(params[:id])
    else
      authorization_failure!("You are not authorized to edit this E-Mail address")
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
      :email_address => record.email_address.to_s
    }
  end
end
