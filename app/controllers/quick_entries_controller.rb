#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class QuickEntriesController < ApplicationController
  required_permissions :none
  
  
  def new
    flash.clear
    unless params[:quick_entry][:for_field].blank?
      party = current_account.parties.find_by_display_name(params[:quick_entry][:for_field])
      if party
        case params[:quick_entry][:save_to_field]
          when 'tags'
            party.tag_list = party.tag_list + ", " + params[:quick_entry][:input]
            party.save!
            flash_success "Tags #{params[:quick_entry][:input]} added to #{party.display_name}"
          when 'notes'
            note = party.notes.build(:body => params[:quick_entry][:input])
            note.created_by = note.updated_by = current_user
            note.name = current_user.display_name
            note.account_id = current_account.id
            
            if note.save
              flash_success "Notes #{params[:quick_entry][:input]} added to #{party.display_name}"
            else
              flash_failure "Adding Notes to #{party.display_name} failed"
            end
          else
        end    
      else
        flash_failure "Quick entry failed: User #{params[:quick_entry][:for_field]} not found"
      end
    else
      flash_failure "Please enter a user in the Quick Entry For field"
    end
    respond_to do |format|
      format.js
    end
  end

  def auto_complete_for_field
    @for_fields = current_account.parties.find(:all, :select => 'DISTINCT(display_name)', 
      :limit => 15, :conditions => [ 'LOWER(display_name) LIKE ?',
      '%' + request.parameters[:quick_entry][:for_field].downcase + '%' ])
    
    render :inline => "<%= auto_complete_result(@for_fields, 'display_name') %>"
  end
  
  def auto_complete_save_to_field
    @save_to_fields = %w(tags notes)
    @save_to_fields.delete_if{|s| !s.include? request.parameters[:quick_entry][:save_to_field].downcase}
    @save_to_fields.map!{|s| {:id => s}}

    render :inline => "<%= auto_complete_result(@save_to_fields, :id) %>"
  end
end
