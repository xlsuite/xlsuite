#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FoldersController < ApplicationController
  layout "assets_two-columns"
  required_permissions %w(index new create edit update destroy destroy_collection auto_complete_tag display_new_folder_window filetree) => :edit_files
  before_filter :find_folder, :only => [ :destroy, :update, :edit]
  before_filter :find_root_folders, :only => %w(index new)
  before_filter :load_available_groups, :only => %w(index new display_new_folder_window edit)
  before_filter :find_common_folder_tags, :only => %w(index new display_new_folder_window edit)
  
  def index    
    params[:ids] = "0" if params[:ids].blank?
    ids = params[:ids].scan(/\d+/)
    
    root_assets = ids.delete("0")
    conditions = "assets.folder_id IN(#{params[:ids]})" unless params[:ids].blank?
    if root_assets
      if conditions 
        conditions << " OR assets.folder_id IS NULL"
      else
        conditions = "assets.folder_id IS NULL"
      end
    end
    @current_total_asset_size = current_account.current_total_asset_size
    @cap_total_asset_size = current_account.cap_total_asset_size
    respond_to do |format|
      format.html
      format.js 
      format.json do
        case params[:scope]
          when /mine/i
            @assets_proxy = current_user.assets
          else
            @assets_proxy = current_account.assets
          end
        
        params[:start] = 0 unless params[:start]
        params[:limit] = 50 unless params[:limit]
        
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => (params[:sort].blank? || !Asset.columns.map(&:id).include?(params[:sort].strip)) ? "filename ASC, updated_at DESC" : "#{params[:sort]} #{params[:dir]}") 
       
    
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        
        conditions = "assets.parent_id IS NULL AND (#{conditions})"
        
        @assets = @assets_proxy.search(query_params, search_options.merge(:conditions => "#{conditions}"))
        @assets_count = @assets_proxy.count_results(query_params, :conditions => "#{conditions}")
        
        domain_name = current_domain.name
        
        @assets = @assets.map{|e| e.to_json("http://#{current_domain.name}/z/#{e.file_directory_path}")}
        render(:text => JsonCollectionBuilder::build(@assets, @assets_count))
      end
    end
  end
  
  def filetree
    case params[:cmd]
      when "get"
        node_id = params[:node].split('_').last
        if node_id == "0"
          return render_filetree_json_response(current_account.folders.roots(:order => "name").reject{|child| !child.viewable_by?(current_user)})
        else
          folders = current_account.folders.find(node_id).children
          return render_filetree_json_response(folders)
        end
      when "newdir"
        dir_array = params[:dir].split('/')
        dir_array.shift
        new_folder_name = dir_array.pop
        folder = current_account.folders.find_by_path(dir_array.join('/'))
            
        @folder = current_account.folders.build(:name => new_folder_name)
        #save now if the new folder does not have to be moved
        @folder.owner = current_user
        @folder.par_id = folder.id if folder
        begin
        Folder.transaction do
          @folder.save!
          return render(:json => {:success => true, :new_id => "folder_#{@folder.id}"}.to_json)
        end
        rescue
          return render(:json => {:success => false, :error => @folder.errors.full_messages}.to_json)
        end
      when "asset_move"
        errors = []
        folder_id = params[:folder_id]
        begin
        Folder.transaction do
          current_account.assets.find(params[:asset_ids].split(',')).to_a.each do |asset|
            folder_id = nil if folder_id == "0"
            asset.folder_id = folder_id
            errors << "#{asset.filename}: #{asset.errors.full_messages.join(',')} in the folder #{folder_id ? ('"'+current_account.folders.find(folder_id).name+'"') : '"Root"'}\n" unless asset.save
          end
          raise unless errors.blank?
          return render(:json => {:success => true}.to_json)
        end
        rescue
          return render(:json => {:success => false, :errors => errors.join(',')}.to_json)
        end
      when "rename"        
        new_file_name = params[:newname].split('/').last
        if params[:newparentid]
          new_parent_id = params[:newparentid] == "folder_0" ? 0 : params[:newparentid].split('_').last
        end
        source_id = params[:sourceid].split('_').last
        @folder = current_account.folders.find(source_id)
        if !new_parent_id
          # this is a folder rename only
          @folder.name = new_file_name
          @folder.par_id = @folder.parent_id
          @updated = @folder.save
        else
          @folder.par_id = new_parent_id == 0 ? nil : new_parent_id
          @updated = @folder.save
        end
        return render(:json => {:success => @updated, :errors => @folder.errors.full_messages}.to_json)
      when "upload"
        parent_folder = current_account.folders.find_by_path(params[:path].gsub(/^root\//i, ''))
        @results = {}
        @uploaded_data_param = params.select{|k,v| k =~ /ext-gen\d+/}
        @errors = []
        @uploaded_data_param.each do |upload_data|
          @asset = current_account.assets.build(:uploaded_data => upload_data.last, :zip_file => params[:zip_file], :tag_list => params[:tag_list])
          @asset.owner = current_user
          @asset.folder = parent_folder if parent_folder
          saved = @asset.save
          @errors << @asset.errors.full_messages unless @errors.index(@asset.errors.full_messages) || @asset.errors.full_messages.blank?
          @results[upload_data.first] = {:saved => saved, :errors => @asset.errors.full_messages}
        end
          respond_to do |format|
            format.html do
              responds_to_parent do 
                render :update do |page|
                  @results.each do |k, v|
                    page << "var record = xl.fileTreePanel.getUploadPanel().store.getById(#{k.to_json});"
                    if v[:saved]
                      page << "record.set('state', 'done');"
                      page << "record.set('error', '');"
                    else
                      page << "record.set('state', 'failed');"
                      page << "record.set('error', 'Upload failed: #{v[:errors]}');"
                    end
                  end
                  page << "record.commit();"
                  page << "xl.runningGrids.get('assets').getStore().reload();"
                  unless @errors.blank?
                    page << "Ext.Msg.alert('Upload failed', '#{@errors.join(",")}')" 
                  end
                  page << "xl.fileTreePanel.getUploadPanel().fireEvent('allfinished');"
                end
              end            
            end
          end
      when "delete"
        @folder = current_account.folders.find_by_path(params[:file].gsub(/^root\//i, ''))
        if @folder.destroy
          return render(:json => {:success => true}.to_json)
        else
          return render(:json => {:success => false, :errors => @folder.errors.full_messages.join(',')}.to_json)
        end
   end
   return
  end
  
  def new
    @folder = Folder.new
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    @folder = current_account.folders.build(params[:folder])
    #save now if the new folder does not have to be moved
    @folder.owner = current_user
    @folder.par_id = params[:parent_id]
    @folder.inspect #need this line or save fails?!?
    Folder.transaction do
      @folder.save!
      @created = true
      flash_success 'Folder created sucessfully'
      display_folder = params[:parent_id].blank? ? @folder.id.to_s : params[:parent_id]
    end
    respond_to do |format|
      format.js
      format.html
    end  
  rescue
    flash_failure "Folder name has already been taken"
    @folders = current_account.folders.roots(:order => "name")
    respond_to do |format|
      format.js
      format.html
    end
  end
  
  def edit
    @parent = @folder.parent
    params[:selection_id] = @parent ? @parent.id : 0
    respond_to do |format|
      format.js
    end
  end
  
  def update
    tags = params[:folder].delete(:tag_list)
    @folder.par_id = params[:parent_id]
    @folder.tag_list = @folder.tag_list + ", " + tags unless tags.blank? 
    %w(private inherit pass_on_attr).each do |boolean_field|
      params[:folder][boolean_field.to_sym] = params[:folder].has_key?(boolean_field)
    end
    begin
      if @folder.update_attributes!(params[:folder])     
        @updated = true
        flash_success :now, "Folder was successfully updated."
      end
    rescue ActiveRecord::RecordInvalid
      @updated = false
      flash_failure :now, @folder.errors.full_messages()
    end
    respond_to do |format|
      format.html
      format.js do
        render(:json => {:success => @updated, :flash => flash[:notice].to_s, :folder_name => @folder.name}.to_json)
      end
    end
  end
  
  def destroy
    parent_id = @folder.parent_id
    @folder.destroy
    flash_success "Folder was successfully destroyed."
    redirect_to parent_id.blank? ? assets_path : folders_path(:ids => parent_id)
  end

  def auto_complete_tag
    @tags = current_account.folders.tags_like(params[:q])
    render_auto_complete(@tags)
  end
  
  def display_new_folder_window
    @folder = current_account.folders.new()
    respond_to do |format|
      format.js { render :action => 'show_new_folder_window'}
    end
  end
  
  protected
  def find_folder
    @folder = current_account.folders.find(params[:id])
    @folder.update_tags
  end
  
  def find_root_folders
    @folders = current_account.folders.roots(:order => "name").reject{|child| !child.viewable_by?(current_user)}
  end
  
  def load_available_groups
    @available_groups = current_account.groups.find(:all, :order => "name")
  end
  
  def find_common_folder_tags
    @common_folder_tags = current_account.folders.tags(:order => "count DESC, name ASC") 
  end
  
  def render_filetree_json_response(folders)
    folders_hash = []
    folders.to_a.each do |folder|
      f = { :text => folder.name, :iconcls => "folder", :disabled => false, :leaf => false, :id => "folder_#{folder.id}"}
      folders_hash << f
    end
    render :json => folders_hash.to_json
  end
end
