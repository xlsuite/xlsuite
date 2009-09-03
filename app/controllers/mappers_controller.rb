#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MappersController < ApplicationController

  required_permissions %w(index) => "current_user?", %w(create edit update destroy) => :edit_mappings
  before_filter :find_mapper, :only => %w(update destroy)
  
  # Display a list of mapper objects created
  def index
    @mappers = current_account.mappers.find(:all)
  end
  
  # Save a mapper object with specified params
  def create
    @mapper = current_account.mappers.build(params[:mapper])
    @mapper.mappings = Mapper.decode_mappings(params[:mappings])
    if params[:import] && params[:import][:id]
      import = current_account.imports.find(params[:import][:id])
      @failure_messages = []
      if !@mapper.save
        @failure_messages += @mapper.errors.full_messages
        @failure_messages.flatten!
        flash_failure :now, @failure_messages
      else
        import.mappings = @mapper.mappings
        import.save!
        flash_success :now, "Default mapper #{@mapper.name} successfully created"
      end
      @taken = @failure_messages.index("Name has already been taken")
      @mapper = current_account.mappers.find_by_name(@mapper.name) if @taken
      respond_to do |format|
        format.html do
          redirect_to import_path(import)
        end
        format.js do
          @mappers = current_account.mappers.find(:all, :order => "name ASC")
          render :action => 'create.rjs', :content_type => 'text/javascript; charset=utf-8', :layout => false 
        end
      end
      return
    end
    flash_failure "Not the right flow. Mapper is still saved though...."
    redirect_to mappers_path
  end
  
  # Render the edit page of a mapper object
  def edit
    @mappings = params[:id] =~ /default(\d)/i ? Mapper.default_mappings[$1.to_i-1] : current_account.mappers.find(params[:id]).mappings
    respond_to do |format|
      format.html
      format.js do 
        render :action => 'edit.rjs', :content_type => 'text/javascript; charset=utf-8', :layout => false 
      end
    end
  end
  
  # Update a particular mapper object with specified params
  def update
    @mapper.attributes = params[:mapper]
    @mapper.mappings = Mapper.decode_mappings(params[:mappings])
    if @mapper.save
      flash_success :now, "Mapper successfully updated"
      redirect_to mappers_path
    else
      flash_failure @mapper.errors.full_messages
      redirect_to edit_mapper_path(@mapper)
    end
  end
  
  # Permanently destroy a specified mapper object
  def destroy
    @mapper.destroy
    flash_success :now, "Mapper successfully destroyed!"
    redirect_to mappers_path
  end

protected
  def find_mapper
    @mapper = current_account.mappers.find(params[:id])
  end
end
