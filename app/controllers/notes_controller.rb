#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class NotesController < ApplicationController
  required_permissions :edit_party

  before_filter :load_party
  before_filter :load_note, :only => %w(edit update destroy)
  
  def index
    respond_to do |format|
      format.json do
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "created_at DESC" : "#{params[:sort]} #{params[:dir]}") 
        conditions = {}
        search_options.merge!(conditions)
        
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        
        @notes = @party.notes.search(query_params, search_options)
        @notes_count = @party.notes.count_results(query_params, conditions)
        
        render :json => {:collection => self.assemble_records(@notes), :total => @notes_count}.to_json
      end
    end
  end
  
  def create
    @note = @party.notes.build(params[:note])
    @note.created_by = @note.updated_by = current_user
    @note.account_id = current_account.id
    @note.name = current_user.full_name
    @created = @note.save
    if @created then
      messages = "New note successfully created"
    else
      messages = render_error_messages_for(:note)
    end
    respond_to do |format|
      format.js do
        render :json => {:success => @created, :messages => messages}.to_json
      end
    end
  end
  
  def update
    @note.attributes = params[:note]
    @updated = @note.save
    respond_to do |format|
      format.js do
        response = truncate_record(@note.reload)
        if !@updated
          response.merge!(:flash => "Error:")
        end
        render :json => response.to_json
      end
    end
  end
  
  def destroy
    if @note.destroy
      messages = "Note successfully destroyed"
    else
      messages = @note.errors.full_messages.join(",")
    end
    respond_to do |format|
      format.js do
        render :json => {:messages => messages}.to_json
      end
    end
  end
  
  protected
  def load_party
    @party = current_account.parties.find(params[:party_id])
  end
  
  def load_note
    @note = @party.notes.find(params[:id])
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
      :body => record.body.to_s, 
      :created_at => record.created_at.to_s, 
      :updated_at => record.updated_at.to_s, 
      :created_by_name => record.created_by ? record.created_by.name.to_s : "N/A", 
      :updated_by_name => record.updated_by ? record.updated_by.name.to_s : "N/A",
      :private => record.private
    }
  end
end
