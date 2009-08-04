#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "net/http"
require "fastercsv"

class ImportsController < ApplicationController
  before_filter :check_account_authorization, :only => %w(new_scrape scrape)
  required_permissions %w(index summary summaries) => "current_user?", %w(go) => :allow_importing, 
      %w(new create show edit update destroy save destroy_all new_scrape scrape) => :edit_imports
  
  before_filter :load_import, :except => %w(index new create destroy_all summaries new_scrape scrape)
  before_filter :load_groups, :only => %w(edit new_scrape)
  
  helper MappersHelper
  
  # Display list of import files? What to display? There is no title nor filename to display only party name 
  def index
    @imports = current_account.imports.find(:all)
  end
  
  # Render a layout that asks user for an import file
  def new
    @import = Import.new
  end
  
  def new_scrape
  end
  
  # Save the uploaded import file
  def create
    if params[:plaxo] && params[:import][:csv]
      params[:import][:csv] = params[:import][:csv].gsub(",", "\n").gsub(" <", ",").gsub(">", "").gsub("\"", "")
    end
    if params[:import][:csv_from_url]
      full_url = params[:import][:csv_from_url]
      url = params[:import].delete("csv_from_url").gsub("http://", "").split('/')
      
      csv = ""
      
      Net::HTTP.start(url.shift) { |http|
        http.request_get('/'+url.join('/')) {|res|
          csv = res.read_body
        }
      }
      FasterCSV.parse(csv)
      params[:import][:csv] = csv
      params[:import][:filename] = full_url
      if full_url =~ /getyou\.info/
        params[:mappings] = {:map => { "1"=>{:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"},
                           "2"=>{:name=>"Other", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"},
                           "3"=>{:name=>"Other", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"},
                           "4"=>{:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"} }}
      end
    end
    @import = current_account.imports.build(params[:import])
    @import.party = current_user
    @import.mappings = Mapper.decode_mappings(params[:mappings])
    @import.save!
    redirect_to edit_import_path(@import)
  rescue CSV::IllegalFormatError, FasterCSV::MalformedCSVError
      flash_failure "Error: Could not parse CSV file"
      redirect_to(new_import_path)
  end
  
  # Note: to use this in development mode, set config.cache_classes to true in development.rb
  def scrape
    @import = current_account.imports.build(params[:import])
    @import.party = current_user
    @import.scrape = true
    @import.state = "Waiting"
    @import.mappings = Mapper.decode_mappings(params[:mappings].merge({:map=>{ "1"=>{:name=>"", :field=>"company_name", :tr=>"As-is", :model=>"Party"}, 
                                                        "2"=>{:name=>"Main", :field=>"email_address", :tr=>"As-is", :model=>"EmailContactRoute"},
                                                        "3"=>{:name=>"Main", :field=>"number", :tr=>"As-is", :model=>"PhoneContactRoute"}, 
                                                        "4"=>{:name=>"Company", :field=>"url", :tr=>"As-is", :model=>"LinkContactRoute"}, 
                                                        "5"=>{:name=>"Main", :field=>"line1", :tr=>"As-is", :model=>"AddressContactRoute"},
                                                        "6"=>{:name=>"Main", :field=>"city", :tr=>"As-is", :model=>"AddressContactRoute"}, 
                                                        "7"=>{:name=>"Main", :field=>"state", :tr=>"As-is", :model=>"AddressContactRoute"}, 
                                                        "8"=>{:name=>"Main", :field=>"zip", :tr=>"As-is", :model=>"AddressContactRoute"},
                                                        "9"=>{:name=>"", :field=>"avatar", :tr=>"As-is", :model=>"Party"} }}))
                   
    @import.save!
    MethodCallbackFuture.create!(:model => @import, :method => :go!, :account => current_account, :owner => current_user)
    render :action => 'go'
  end
  
  # Render the edit page of an import
  def edit
    @data = @import.first_x_lines(3);
    get_mappings_of_other_import_with_same_filename
    @mappers = current_account.mappers.find(:all, :order => "name ASC")
    respond_to do |format|
      format.html
      format.js do
        render :action => 'edit.rjs', :content_type => 'text/javascript; charset=utf-8', :layout => false 
      end
    end
  end
  
  # Update an import
  def update
    @import.party = current_user
    @import.attributes = params[:import]
    @import.mappings = Mapper.decode_mappings(params[:mappings])
    @import.save!
    flash_success "Import successfully updated"
    redirect_to imports_path
  end
  
  # Delete an import from the DB
  def destroy
    if @import.destroy
      flash_success "Import file successfully deleted"
    else
      flash_failure "Import deletion failed!"
    end
    redirect_to imports_path
  end
  
  # Execute the import
  def go
    mapping_values = []
    params[:mappings][:map].each_value{|val_hash| mapping_values << val_hash.reject{|k, v| k.to_s=="tr"}.values}
    if mapping_values.to_s.blank?
      @data = @import.first_x_lines(3);
      @mappers = current_account.mappers.find(:all, :order => "name ASC")
      flash_failure "Mappings can't be blank. Please drag and drop available mapping into the 'Store In' column"
      return redirect_to(edit_import_path(@import))
    end

    @import.attributes = params[:import]
    @import.mappings = Mapper.decode_mappings(params[:mappings].clone)
    @import.state = "Scheduled"
    @import.imported_rows_count = 0
    @import.save!

    # Schedule the import as soon as possible
    MethodCallbackFuture.create!(:model => @import, :method => :go!, :account => current_account, :owner => current_user)
  end
  
  # Save the mapping of a particular import
  def save
    @import.mappings = Mapper.decode_mappings(params[:mappings])
    @import.save!
    render :action => 'save.rjs', :content_type => 'text/javascript; charset=utf-8', :layout => false 
  end
  
  def destroy_all
    ids = params[:import_ids]
    if current_account.imports.destroy(ids)
      flash_success "#{ids.size} items are successfully deleted"
    else
      flash_failure "Destroy items failed"
    end
    redirect_to imports_path
  end
  
  def summaries
    @imports = current_account.imports.find(params[:import_ids])
  end
  
  def summary
  end

protected

  def get_mappings_of_other_import_with_same_filename
    if @import.has_blank_mappings?
      another_import = current_account.imports.find(:all, :conditions => ["filename = ? and id <> ?", @import.filename, @import.id], :order => "created_at DESC").first
      @import.mappings[:map] = another_import.mappings[:map] if another_import
    end
    if @import.has_blank_mappings?
      mapper = current_account.mappers.find(:all, :conditions => ["name = ?", @import.filename], :order => "created_at DESC").first
      @import.mappings[:map] = mapper.mappings[:map] if mapper
    end
    @mappings = @import.mappings || {}
  end
  
  def load_import
    @import = current_account.imports.find(params[:id])
  end
  
  def load_groups
    @groups = current_account.groups
  end
  
  def check_account_authorization
    return if current_account.options.imports_scraper?
    @authorization = "Imports Scraper"
    access_denied
    false
  end
end
