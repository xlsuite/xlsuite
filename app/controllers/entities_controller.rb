#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EntitiesController < ApplicationController
  required_permissions %w(index) => [:view_entities, :edit_entities, {:any => true}],
    %w(new create edit update destroy destroy_collection tagged_collection) => :edit_entities

  before_filter :find_common_entities_tags, :only => [:new, :edit]
  before_filter :find_entity, :only => [:edit, :update, :destroy, :new_link, :create_link, :new_phone, :create_phone,
                                        :new_address, :create_address, :new_email, :create_email]
  before_filter :set_routes_instance_variables, :only => [:edit]

  helper ContactRoutesHelper

  def index
    respond_to do |format|
      format.js
      format.json do
        process_index
        render(:text => JsonCollectionBuilder::build_from_objects(@entities, @entities_count))
      end
    end
  end

  def new
    @entity = Entity.new
    respond_to do |format|
      format.js
    end
  end

  def create
    @entity = current_account.entities.build(params[:entity])
    @entity.creator = current_user
    @created = false
    @created = @entity.save
    if @created
      flash_success :now, "#{@entity.classification} #{@entity.name} successfully created"
    else
      flash_failure :now, @entity.errors.full_messages
    end
    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @entity.attributes = params[:entity]
    @entity.editor = current_user
    @updated = false
    begin  
      @updated = @entity.save  
    rescue ActiveRecord::RecordInvalid
    end
    if !@updated
      error_messages = @entity.errors.full_messages
      error_messages += @entity.email.errors.full_messages
      error_messages += @entity.link.errors.full_messages
      error_messages += @entity.phone.errors.full_messages
      flash_failure :now, error_messages
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    respond_to do |format|
      format.js
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    current_account.entities.find(params[:ids].split(",").map(&:strip)).to_a.each do |entity|
      next unless entity.writeable_by?(current_user)
      @destroyed_items_size += 1 if entity.destroy
    end

    flash_success :now, "#{@destroyed_items_size} entity(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end

  def tagged_collection
    @tagged_items_size = 0
    current_account.entities.find(params[:ids].split(",").map(&:strip)).to_a.each do |entity|
      next unless entity.writeable_by?(current_user)
      entity.tag_list = entity.tag_list + " #{params[:tag_list]}"
      @tagged_items_size += 1 if entity.save
    end

    respond_to do |format|
      format.js do
        flash_success :now, "#{@tagged_items_size} entities has been tagged with #{params[:tag_list]}"
      end
    end
  end

  %w(address phone email link).each do |route|
    class_eval <<-EOF
      def new_#{route}
        instance_variable_set("@#{route}", #{route.capitalize}ContactRoute.new(:routable => @entity))
        render :partial => "#{route}_contact_route", :object => instance_variable_get("@#{route}")
      end
      
      def create_#{route}
        instance_variable_set("@#{route}", @entity.#{route=~/email/i ? "email_addresses" : route.pluralize}.build(params[:#{route=~/email/i ? "email_address" : route}].values.first))
        if instance_variable_get("@#{route}").save then
          instance_variable_set("@dom_to_remove", #{route.capitalize}ContactRoute.new)
          instance_variable_set("@partial", "#{route}_contact_route")
          instance_variable_set("@object", instance_variable_get("@#{route}"))
          respond_to do |format|
            format.js { render :template => "entities/create_route" }
          end
        else
          raise "Do Something!"
        end
      end
    EOF
  end
  
  protected

  def find_common_entities_tags
    @common_tags = current_account.entities.tags(:order => "count DESC, name ASC")
  end

  def process_index
    @entities = current_account.entities.find(:all)
    @entities_count = current_account.entities.count
  end

  def find_entity
    @entity = current_account.entities.find(params[:id])
  end
  
  def set_routes_instance_variables
    %w(address phone link email).each do |attr|
      instance_variable_set("@new_#{attr}_url", send("new_#{attr}_entity_path", @entity))
    end
  end
end
