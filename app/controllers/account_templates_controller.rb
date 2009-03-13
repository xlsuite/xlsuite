#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountTemplatesController < ApplicationController
  required_permissions %w(new edit update create) => "current_user?"
  
  before_filter :load_account_template, :only => [:edit, :update, :images, :multimedia, :other_files, :upload_file, :destroy]
  
  def new
    @account_template = AccountTemplate.find_by_trunk_account_id(self.current_account.id)
    respond_to do |format|
      format.html
      format.js do
        if @account_template
          render :template => "account_templates/edit.rjs"
        else
          @account_template = AccountTemplate.new
        end
      end
    end
  end
  
  def create
    @account_template = AccountTemplate.new(params[:account_template].reverse_merge(self.features_off_by_default_hash))
    @account_template.trunk_account_id = self.current_account.id
    @created = @account_template.save
    respond_to do |format|
      format.html
      format.js do
        flash_success :now, "Account successfully published as a template" if @created
        self.render_json_response
      end
    end
  end
  
  def update
    @account_template.attributes = params[:account_template].reverse_merge(self.features_off_by_default_hash)
    @updated = @account_template.save
    respond_to do |format|
      format.html
      format.js do
        flash_success :now, "Account template updated" if @updated
        self.render_json_response
      end
    end
  end
  
  def destroy
    @destroyed = @account_template.destroy
    respond_to do |format|
      format.html
      format.js do
        flash_success :now, "Account template #{@account_template.name} unpublished successfully"
        render :json => {:flash => flash[:notice].to_s, :success => @destroyed }.to_json
      end
    end
  end
  
  def push
    @pushed = self.current_account.account_template_as_trunk.push_trunk_to_stable!(params[:push])
    respond_to do |format|
      format.html
      format.js do
        render :json => {:success => @pushed}.to_json
      end
    end
  end

  def images
    @images = @account_template.images
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@images, {:size => params[:size]})
      end
    end
  end
  alias_method :pictures, :images
  
  def multimedia
    @multimedia = @account_template.multimedia
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@multimedia, {:size => params[:size]})
      end
    end
  end
  
  def other_files
    @other_files = @account_template.other_files
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@other_files, {:size => params[:size]})
      end
    end
  end
  
  def upload_file
    Account.transaction do
      @file = current_account.assets.build(:filename => params[:Filename], :uploaded_data => params[:file])
      @file.content_type = params[:content_type] if params[:content_type]
      @file.save!
      @view = @account_template.views.create!(:asset_id => @file.id, :classification => params[:classification])

      respond_to do |format|
        format.js do
          render :json => {:success => true, :message => 'Upload Successful!'}.to_json
        end
      end
    end

    rescue
      @messages = []
      @messages << @file.errors.full_messages if @file
      @messages << @view.errors.full_messages if @view
      logger.debug {"==> #{@messages.to_yaml}"}
      respond_to do |format|
        format.js do
          render :json => {:success => false, :error => @messages.flatten.delete_if(&:blank?).join(',')}.to_json
        end
      end
  end
  
  protected

  def render_json_response
    errors = (@account_template.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :account_template})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @account_template.id, :success => @updated || @created }.to_json
  end
  
  def load_account_template
    @account_template = AccountTemplate.find(params[:id])
  end
  
  def features_off_by_default_hash
    hash = {}
    AccountTemplate.functionality_column_names.each do |column_name|
      hash.merge!(column_name => "0")
    end
    hash
  end
  
  def authorized?
    return false unless self.current_user.id == self.current_account.owner.id
    true
  end
end
