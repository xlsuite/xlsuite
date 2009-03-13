#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SearchController < ApplicationController
  required_permissions %w(async_get_name_id_hashes perform_quick_search perform_advanced_search iframe_quick_search iframe_advanced_search) => true,
      %w(show_saved_search remove_saved_search save_search) => "current_user?"
  layout "two-columns"

  # implement normal search
  def perform_quick_search
    @search_text = params[:search_text].blank? ? "" : params[:search_text] 
    
    query_params = @search_text
    count_results = current_account.fulltext_rows.count_results(query_params)

    if (count_results < 1)
      unless query_params.blank? 
        query_params = query_params.split(/\s+/)
        query_params = query_params.map {|q| q+"*"}.join(" ")
      end
    end
    
    @paginator = ::Paginator.new(current_account.fulltext_rows.count_results(query_params), 30) do |offset, limit|
      current_account.fulltext_rows.search(query_params, :offset => offset, :limit => limit)
    end

    @page = @paginator.page(params[:page])
    @rows = @page.items
    respond_to do |format|
      format.html do
        render :action => 'quick_search_results'
      end
      format.js do
        @_request_uri = request.request_uri
        render :action => 'render_search_in_iframe.rjs'
      end
    end
  end
  
  # implement advanced search
  def perform_advanced_search
    respond_to do |format|
      format.html do
        if params[:id].blank?
          @search_params = []
          @sort_params = []
          unless params[:search_line].blank?
            for i in 1..params[:search_line].size
              @search_params << params[:search_line]["#{i}"]
            end
          end
          unless params[:sort_by].blank?
            for i in 1..params[:sort_by].size
              @sort_params << params[:sort_by]["#{i}"]
            end
          end
        else
          saved_search = Search.find(params[:id]) rescue nil
          if saved_search.nil?
            render :inline => "Page Not Found", :status => '404', :layout => true
            return
          end
          # convert search_lines and sort_lines to array of hashes
          @search_params = []
          for sl in saved_search.search_lines
            @search_params << sl.to_hash
          end
          @sort_params = []
          for sl in saved_search.sort_lines
            @sort_params << sl.to_hash
          end
        end
        execute_advanced_search
      end
      format.js do
        @_request_uri = request.request_uri
        render :action => 'render_search_in_iframe.rjs'
      end
    end
  end
  
  # show a saved search and load its values on the advanced search fields
  def show_saved_search
    @saved_search = Search.find(params[:id])
    @search_lines = @saved_search.search_lines
    @sort_lines = @saved_search.sort_lines
    render :action => 'update_advanced_search_box', :content_type => 'text/javascript; charset=UTF-8', :layout => false
  end

  # remove a particular saved search
  def remove_saved_search
    begin
      saved_search = Search.find(params[:id])
    rescue
      render :nothing => true
      return
    end
    if saved_search.destroy
      @id = params[:id]
      render :action => 'remove_saved_search', :content_type => 'text/javascript; charset=UTF-8', :layout => false
    else
      render :nothing => true
      return
    end
  end

  # save an advanced search configuration
  def save_search
    @saved_search = current_user.searches.find_by_name(params[:saved_search][:name])
    if !@saved_search.nil? && params[:button_clicked] !~ /overwrite/
      render :action => 'show_overwrite_confirmation_box', :content_type => 'text/javascript; charset=UTF-8', :layout => false
      return
    elsif !@saved_search.nil? && params[:button_clicked] =~ /overwrite/
      @saved_search.description = params[:saved_search][:description]
      @saved_search.search_lines.clear
      @saved_search.sort_lines.clear
    elsif @saved_search.nil?
      @saved_search = Search.new(params[:saved_search])
      @saved_search.party = current_user
      @saved_search.account = current_account
    else
      return
    end
    search_params = []
    for i in 1..params[:search_line].size
      search_params << params[:search_line]["#{i}"]
    end
    sort_params = []
    for i in 1..params[:sort_by].size
      sort_params << params[:sort_by]["#{i}"]
    end
    for i in 1..search_params.size
      search_line = SearchLine.new()
      search_line.priority = i
      search_line.subject_name = search_params[i-1]["subject_name"]
      search_line.subject_option = search_params[i-1]["subject_option"]
      search_line.subject_value = search_params[i-1]["subject_value"]
      search_line.subject_exclude = search_params[i-1]["subject_exclude"] ? true : false
      @saved_search.search_lines << search_line if search_line.save!
    end
    for i in 1..sort_params.size
      sort_line = SortLine.new()
      sort_line.priority = i
      sort_line.order_name = sort_params[i-1]["order_name"]
      sort_line.order_mode = sort_params[i-1]["order_mode"]
      @saved_search.sort_lines << sort_line if sort_line.save!
    end
    @existed = !@saved_search.new_record?
    @saved_search.save!
    render :action => 'add_saved_search', :content_type => 'text/javascript; charset=UTF-8', :layout => false
  end

  def async_get_name_id_hashes
    searches = Search.find :all, :order => "name"
    name_ids = searches.collect { |search| { 'name' => search.name, 'id' =>  search.id.to_s } }
    
    # [{name: "Access", id: "5"}, {name: "Admins", id: "6"}, {name: "Adminx2", id: "37"}]
    wrapper = {'total' => name_ids.size, 'collection' => name_ids}
    render :json => wrapper.to_json, :layout => false
  end
  
protected

  def execute_advanced_search
    sorted_bys, advanced_search_results = AdvancedSearch::perform_search(@search_params, @sort_params, :account => current_account)
    @num_of_results = advanced_search_results.size
    @headers = []
    for sb in sorted_bys
      @headers << sb.humanize
    end
    @headers << "Contact"
    items_per_page = params[:show] || 10
    items_per_page = @num_of_results if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i

    @paginator = ::Paginator.new(advanced_search_results.size, items_per_page) do |offset, limit|
      advanced_search_results.slice(offset, limit)
    end
    @page = @paginator.page(params[:page])
    @search_results = @page.items
    @path_parameters = request.request_uri
    render :action => 'advanced_search_results'
  end
end
