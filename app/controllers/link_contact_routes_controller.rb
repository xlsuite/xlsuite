#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LinkContactRoutesController < ApplicationController
  before_filter :load_routable
  before_filter :load_link, :except => %w(index new create create_new destroy_collection)
  required_permissions %w(index new edit) => true,
      %w(show create create_new update update_new destroy destroy_collection) => [:edit_party, :edit_own_account, 
        :edit_own_contacts_only, {:any => true}]

  helper :contact_routes
  
  def index
    respond_to do |format|
      format.json do
        @link = @routable.links
        @links_count = @routable.links.count
        render :json => {:collection => self.assemble_records(@link), :total => @links_count}.to_json
      end
    end
  end
  
  def new
    @link = LinkContactRoute.new(:routable => @routable)
    show
  end

  def show
    render :partial => "link_contact_route", :object => @link, :layout => false
  end

  def create
    @link = @routable.links.build(params[:link].values.first)
    if @link.save then
      respond_to do |format|
        format.js { render :action => "create" }
        format.html { redirect_to party_path(@link.routable) }
      end
    else
      raise "Do something !"
    end
  end
  
  def create_new
    @link = @routable.links.build(params[:link])
    @created = @link.save
    if @created then
      messages = "New link successfully created"
    else
      messages = render_error_messages_for(:link)
    end
    respond_to do |format|
      format.js do
        render :json => {:success => @created, :messages => messages}.to_json
      end
    end
  end

  def update
    attrs = params[:link][params[:id]]
    if attrs && attrs.has_key?(:url) && attrs[:url].blank? then
      destroy
    elsif @link.update_attributes(attrs) then
      respond_to do |format|
        format.js { render :action => "update" }
        format.html { redirect_to party_path(@link.routable) }
      end
    else
      raise "Do something !"
    end
  end
  
  def update_new
    @link.attributes = params[:link]
    @updated = @link.save
    respond_to do |format|
      format.js do
        response = assemble_record(@link.reload)
        if !@updated
          response.merge!(:flash => "Error:")
        end
        render :json => response.to_json
      end
    end
  end

  def destroy
    if @link.destroy then
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
    @routable.links.find(params[:ids].split(",").map(&:strip)).each do |link|
      if link.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    messages = []
    messages << "#{@destroyed_items_size} link(s) successfully deleted" if @destroyed_items_size > 0
    messages << "#{@undestroyed_items_size} link(s) failed to be destroyed" if @undestroyed_items_size > 0

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

  def load_link
    link_route = LinkContactRoute.find(params[:id])
    @link = if current_user.can?(:edit_party) then
      if @routable then
        @routable.links.find(params[:id])
      else
        link_route
      end
    elsif current_user.can?(:edit_own_contacts_only) && link_route.routable != current_user then
      if @routable && @routable.created_by_id == current_user.id
        @routable.links.find(params[:id])
      else
        link_route if link_route.routable_type = "Party" && link_route.routable.created_by_id == current_user.id
      end
    elsif current_user.can?(:edit_own_account) then
      current_user.links.find(params[:id])
    else
      authorization_failure!("You are not authorized to edit this link")
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
      :url => record.url.to_s
    }
  end
end
