#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AssetsController < ApplicationController
  session :off, :only => :download
  layout "two-columns"
  helper FoldersHelper
  
  required_permissions %w(index new edit create update destroy update_permissions display_new_file_window
                          display_edit auto_complete_tag destroy_collection images tagged_collection image_picker_upload) => :edit_files, 
                       %w(show_all_records_files show download image_picker) => true
  skip_before_filter :login_required, :only => %w(download show image_picker)
  before_filter :load_asset, :only => %w(show edit update destroy display_edit update_permissions images)
  before_filter :ensure_writeable, :only => %w(update destroy)
  before_filter :find_common_asset_tags, :only => %w(show new edit display_edit display_new_file_window)
  before_filter :find_root_folders, :only => %w(index show download new edit)
  before_filter :load_available_groups, :only => %w(new display_new_file_window edit display_edit)  

  def show_all_records_files
    @record_files = Asset.find_users_files(params[:ids], current_account)
    respond_to do |format|
      format.js
    end
  end
  
  def update_permissions
    if params[:reader_id]
      old_auths = @asset.readers
      old_auths_ids = old_auths.to_a.collect{|old| old.id.to_s}
      new_ids = []
      if old_auths_ids.blank?
        new_ids << params[:reader_id]
      else
        new_ids = old_auths_ids.include?(params[:reader_id]) ? old_auths_ids-(params[:reader_id]).to_a : old_auths_ids << params[:reader_id]
      end
      if @asset.update_attributes({:reader_ids=>new_ids})
        respond_to do |format|
          format.js { render :action => 'toggle_reader_throbber.rjs'}
        end
      end
    end
    if params[:writer_id]  
      old_auths = @asset.writers
      old_auths_ids = old_auths.to_a.collect{|old| old.id.to_s}
      new_ids = []
      if old_auths_ids.blank?
        new_ids << params[:writer_id]
      else
        new_ids = old_auths_ids.include?(params[:writer_id]) ? old_auths_ids-(params[:writer_id]).to_a : old_auths_ids << params[:writer_id]
      end
      if @asset.update_attributes({:writer_ids=>new_ids})
        respond_to do |format|
          format.js { render :action => 'toggle_writer_throbber.rjs'}
        end
      end
    end
  end
  
  def display_new_file_window
    if params[:id] && params[:id] != "0"
      @folder = current_account.folders.find(params[:id])
    else
      @folder = current_account.folders.new()
      @folder.id = 0
    end
    @asset = current_account.assets.build
    respond_to do |format|
      format.js { render :action => 'show_new_file_window.rjs'}
    end
  end
  
  def display_edit
    respond_to do |format|
      format.js { render :action => 'show_edit.rjs' }
    end
  end
  
  def index
    case params[:scope]
    when /all/i
      @assets_proxy = current_account.assets
    else
      @assets_proxy = current_user.assets
    end

    @assets = []
    if params[:q].blank?
      @assets = @assets_proxy.find(:all, :conditions => "parent_id IS NULL")
    else
      params[:q].to_s.split(/\s+/).each do |part|
        case part
        when /\Atag:(.*)\Z/i
          @assets << @assets_proxy.get_tagged_with(Tag.parse($1.gsub("+", " ")))
        else
          @assets << @assets_proxy.get_titled_like(part)
        end
      end
      @assets.flatten!
      @assets.uniq!
    end

    @assets = @assets.select {|a| a.readable_by?(current_user)}

    items_per_page = params[:show] || ItemsPerPage
    items_per_page = @assets.size if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i
    @assets_count = @assets.size
    @pager = ::Paginator.new(@assets.size, items_per_page) do |offset, limit|
      @assets[offset, limit]
    end

    @page = @pager.page(params[:page])
    @assets = @page.items

    respond_to do |format|
      format.html
      format.json do
        render(:text => JsonCollectionBuilder.build(@assets, @assets_count))
      end
    end
  end

  def show
    @folder = @asset.folder
    return redirect_to(download_asset_path(@asset)) unless current_user?
    render
  end

  def download
    if params[:id].blank? then
      return render(:missing) if params[:filename].blank?
      @asset = current_account.assets.find_by_path_and_filename(params[:folder], params[:filename])
      if @asset && params[:size]
        @asset = @asset.thumbnails.find_by_thumbnail(params[:size])
      end
    else
      return if load_asset == false
      @asset = @asset.thumbnails.find_by_thumbnail(params[:size]) unless params[:size].blank?
    end
    
    unless @asset
      if params[:size] || (params[:filename] && params[:filename] =~ /_(small|medium|mini|square)\./ && current_account.assets.find_by_path_and_filename(params[:folder], params[:filename].gsub(/_(small|medium|mini|square)\./, ".")))
        return send_file("public/images/thumbisbeinggen.gif", :type => "image/gif", :disposition => "inline")
      else
        return render(:missing)
      end
    end
    return render(:missing) unless @asset.readable_by?(current_user? ? current_user : nil)

    if @asset.content_type =~ /shockwave-flash/i
      disposition = ""
      disposition = params[:disposition].downcase if params[:disposition]
      disposition = "" unless disposition.match(/^(inline|attachment)$/)
  
      disposition = "inline" if disposition.blank?
  
      # Set cache control headers, and any other headers really,
      # according to the asset's wishes
      @asset.http_headers.each do |name, value|
        response.headers[name] = value
      end
  
      if request.env["HTTP_X_SENDFILE_CAPABLE"] == "1" then
        logger.debug {"==> Server is X-Sendfile capable"}
        response.headers["X-Sendfile"] = @asset.full_filename
        send_data("", :filename => @asset.filename,
            :type => @asset.content_type, :disposition => disposition)
      else
        send_data(@asset.send(:current_data), :filename => @asset.filename,
            :type => @asset.content_type, :disposition => disposition)
      end
      return
    end

    %w(controller action filename id size).each do |p|
      params.delete(p)
    end
    
    asset_url = ""
    if @asset.private 
      asset_url = @asset.authenticated_s3_url
      asset_url += "&#{params.to_param}" unless params.empty? 
    else 
      asset_url = @asset.s3_url
      asset_url += "?#{params.to_param}" unless params.empty?
    end
    response.headers.merge!(@asset.http_headers)
    redirect_to asset_url
  end

  def new
    @folder = current_account.folders.find(params[:folder_id]) if params[:folder_id] && params[:folder_id] != "0"
    @asset = current_account.assets.build
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @asset = current_account.assets.build(params[:asset])
    @asset.owner = current_user
    respond_to do |format|
      format.html do
        if params[:ajax] then
          @close = (params[:commit_type] =~ /close/i)
          @created = @asset.save
          if @created
            folder_name = @asset.reload.folder ? @asset.folder.name : "root"
            flash_success :now, "File successfully uploaded to #{folder_name} folder"
          else
            flash_failure :now, "Upload failed: #{@asset.errors.full_messages.join(',')}"
          end
          responds_to_parent do 
            render :update do |page|
              page << "xl.assetPanels.get('assets_new').el.unmask();"
              if @created
                page << "xl.openNewTabPanel('assets_edit_#{@asset.id}', #{edit_asset_path(@asset).to_json});" unless @close
                page << "xl.closeTabPanel('assets_new_nil');"          
                page << refresh_folder_datastore
              end
              page << update_notices_using_ajax_response(:onroot => "parent")
            end
          end
        else
          if @asset.save then
            redirect_to asset_path(@asset)
          else
            find_common_asset_tags
            load_available_groups
            flash_failure "Upload failed"
            ids = params[:asset][:folder_id].blank? ? 0 : params[:asset][:folder_id]
            render :action => "new"
          end
        end
      end
    end
  end
  
  def image_picker_upload
    @asset = current_account.assets.build(params[:asset])
    @asset.owner = current_user  
    @ar_object = params[:object_type].classify.constantize.find(:first, :conditions => ["id=?", params[:object_id]])
    raise ActiveRecord::NotFound if @ar_object.blank? && (params[:set_relation] || params[:set_avatar])
    @created = @asset.save
    if @created
      if params[:set_relation] && @ar_object.respond_to?(:views)
        View.create(:asset => @asset, :attachable => @ar_object)
      end
      if params[:set_avatar] && @ar_object.kind_of?(Party)
        @ar_object.avatar = @asset
        @ar_object.save!
      end
    end
    respond_to do |format|
      format.html do
        if @created
          flash_success :now, "File successfully uploaded"
        else
          flash_failure :now, "Upload failed: #{@asset.errors.full_messages.join(',')}"
        end
        render :inline => %Q`<%= "{success:#{@created}, file_name: '#{@created ? @asset.reload.filename : @asset.filename}', asset_id: #{@created ? @asset.id : 0}, flash: '#{flash_messages_to_s}',reload_store: '#{params[:object_type]}_#{@ar_object.blank? ? 0 : @ar_object.id}_#{params[:mode]}_#{params[:classification]}', asset_download_path: '#{@asset.z_src}'}" %>`
      end
      format.js do
        if @created
          render :json => {:success => true, :asset_url => @asset.z_src, :asset_id => @asset.id, :messages => "Successfully uploaded"}.to_json
        else
          render :json => {:success => false, :messages => "Uploading failed: #{@asset.errors.full_messages.join(',')}"}.to_json
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.html { render }
      format.js
    end
  end

  def update
    if params[:ajax] then
      @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
      @updated = @asset.update_attributes(params[:asset])
      if @updated
        flash_success :now, "File updated"
      else
        flash_failure :now, "File could not be updated"
      end
      responds_to_parent do 
        render :update do |page|
          page << "xl.assetPanels.get('assets_edit_#{@asset.id}').el.unmask();"
          if @updated && @close
            page << "xl.closeTabPanel('assets_edit_#{@asset.id}');"
          end
          page << refresh_folder_datastore
          page << update_notices_using_ajax_response(:onroot => "parent")
          page << "$('#{dom_id(@asset)}_errorMessages').innerHTML = '#{@asset.errors.full_messages.join(',')}';"
        end
      end
    elsif @asset.update_attributes(params[:asset]) then
      respond_to do |format|
        format.html { redirect_to asset_path(@asset) }
        format.js do
          @attribute = params[:asset].keys.first
        end
      end
    else
      find_common_asset_tags
      render :action => :edit
    end
  end

  def destroy
    if @asset.destroy then
      redirect_to assets_path
    else
      find_common_asset_tags
      render :action => :edit
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    if params[:ids]
      current_account.assets.find_all_by_id(params[:ids].split(",").map(&:strip).reject(&:blank?)).each do |asset|
        @destroyed_items_size += 1 if asset.destroy
      end
    end
    flash_success :now, "#{@destroyed_items_size} asset(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def auto_complete_tag
    @tags = current_account.assets.tags_like(params[:q])
    render_auto_complete(@tags)
  end
  
  def tagged_collection
    count = 0
    current_account.assets.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |asset|
      asset.tag_list = asset.tag_list + " #{params[:tag_list]}"
      asset.save
      count += 1
    end
    flash_success :now, "#{count} asset(s) successfully tagged"
    render :update do |page|
      page << update_notices_using_ajax_response(:onroot => "parent")
    end
  end
  
  def images
    @images = @asset.images
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@images, {:size => params[:size]})
      end
    end
  end
  
  def image_picker
    respond_to do |format|
      format.json do
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]

        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        case params[:content_type]
        when /all/i
          condition_option = {:conditions => "assets.parent_id IS NULL"}
        when /multimedia/i
          condition_option = {:conditions => "assets.parent_id IS NULL AND #{Asset::MULTIMEDIA_CONDITIONS}"}
        when /others/i
          condition_option = {:conditions => "assets.parent_id IS NULL AND #{Asset::OTHER_FILES_CONDITIONS}"}
        else
          condition_option = {:conditions => "assets.parent_id IS NULL AND #{Asset::IMAGE_FILES_CONDITION}"}
        end
        search_options.merge!(condition_option)
        
        @assets = current_account.assets.search(query_params, search_options)
        @assets_count = current_account.assets.count_results(query_params, condition_option)

        records = []
        @assets.each do |asset|
          records << {
            :id => asset.id,
            :url => asset.z_src,
            :filename => asset.filename
          }
        end

        render :json => {:total => @assets_count, :collection => records}.to_json
      end
    end
  end

  protected
  def load_asset
    @asset = current_account.assets.find_by_id(params[:id])
    returning(false) {render(:missing)} unless @asset && @asset.readable_by?(current_user? ? current_user : nil)
  end

  def ensure_writeable
    returning(false) {render(:unauthorized)} unless @asset.writeable_by?(current_user)
  end

  def find_common_asset_tags
    mls_numbers = []
    Listing.find_by_sql(["SELECT mls_no, raw_property_data FROM listings WHERE account_id = ?", current_account.id]).map(&:mls_no).compact.each do |mls_no|
      mls_numbers << "'#{mls_no}'" 
    end
    find_options = {:order => "count DESC, name ASC"}
    find_options.merge!({:conditions => "name NOT IN (#{mls_numbers.join(',')})"}) unless mls_numbers.blank?
    @common_tags = current_account.assets.tags(find_options)
  end
  
  def find_root_folders
    @folders = current_account.folders.roots(:order => "name").reject{|root| !root.viewable_by?(current_user)}
  end
  
  def load_available_groups
    @available_groups = current_account.groups.find(:all, :order => "name")
  end
  
  def render_json_response
    errors = (@asset.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :asset})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @asset.id, :success => @updated || @created || false}.to_json
  end 
end
