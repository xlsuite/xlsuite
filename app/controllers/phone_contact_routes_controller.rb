#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PhoneContactRoutesController < ApplicationController
  before_filter :load_routable
  before_filter :load_phone, :except => %w(index new create validate create_new destroy_collection)
  required_permissions %w(index new edit) => true,
      %w(show create create_new update update_new destroy destroy_collection) => [:edit_party, :edit_own_account, 
        :edit_own_contacts_only, {:any => true}]

  helper :contact_routes

  def index
    respond_to do |format|
      format.json do
        @phone = @routable.phones
        @phones_count = @routable.phones.count
        render :json => {:collection => self.assemble_records(@phone), :total => @phones_count}.to_json
      end
    end
  end
  
  def new
    @phone = PhoneContactRoute.new(:routable => @routable)
    show
  end

  def show
    render :partial => "phone_contact_route", :object => @phone, :layout => false
  end

  def create
    @phone = @routable.phones.build(params[:phone].values.first)
    if @phone.save then
      respond_to do |format|
        format.js { render :action => "create" }
        format.html { redirect_to party_path(@phone.routable) }
      end
    else
      raise "Do something !"
    end
  end
  
  def create_new
    @phone = @routable.phones.build(params[:phone])
    @created = @phone.save
    if @created then
      messages = "New phone successfully created"
    else
      messages = render_error_messages_for(:phone)
    end
    respond_to do |format|
      format.js do
        render :json => {:success => @created, :messages => messages}.to_json
      end
    end
  end

  def update
    attrs = params[:phone][params[:id]]
    if attrs && attrs.has_key?(:number) && attrs[:number].blank? then
      destroy
    elsif @phone.update_attributes(attrs) then
      respond_to do |format|
        format.js { render :action => "update" }
        format.html { redirect_to party_path(@phone.routable) }
      end
    else
      raise "Do something !"
    end
  end
  
  def update_new
    @phone.attributes = params[:phone]
    @updated = @phone.save
    respond_to do |format|
      format.js do
        response = assemble_record(@phone.reload)
        if !@updated
          response.merge!(:flash => "Error:")
        end
        render :json => response.to_json
      end
    end
  end

  def destroy
    if @phone.destroy then
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
    @routable.phones.find(params[:ids].split(",").map(&:strip)).each do |phone|
      if phone.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    messages = []
    messages << "#{@destroyed_items_size} phone(s) successfully deleted" if @destroyed_items_size > 0
    messages << "#{@undestroyed_items_size} phone(s) failed to be destroyed" if @undestroyed_items_size > 0

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

  def load_phone
    phone_route = PhoneContactRoute.find(params[:id])
    @phone = if current_user.can?(:edit_party) then
      if @routable then
        @routable.phones.find(params[:id])
      else
        phone_route
      end
    elsif current_user.can?(:edit_own_contacts_only) && phone_route.routable != current_user then
      if @routable && @routable.created_by_id == current_user.id
        @routable.phones.find(params[:id])
      else
        phone_route if phone_route.routable_type = "Party" && phone_route.routable.created_by_id == current_user.id
      end
    elsif current_user.can?(:edit_own_account) then
      current_user.phones.find(params[:id])
    else
      authorization_failure!("You are not authorized to edit this phone")
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
      :number => record.number.to_s,
      :extension => record.extension.to_s
    }
  end
end
