#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BooksController < ApplicationController
  required_permissions :edit_publishings

  before_filter :find_common_books_tags, :only => [:new, :edit]
  before_filter :find_book, :only => [:async_get_relation, :duplicate, :show, :edit, :update, :destroy,
    :async_add_relation, :async_remove_relations_by_ids, :async_upload_image, :async_destroy_image, :async_get_image_ids]
  before_filter :convert_cost_params_to_money, :only => [:create, :update]

  def publishings_view
    respond_to do |format|
      format.js
      format.json do
        books = current_account.books.find(:all)

        records = books.collect do |book|
          currency = book.production_cost.currency
          {
            :id => book.id,
            :printing_date => book.printing_at.to_s,
            :printing_cost => book.printing_cost.cents.to_f / 100,
            :production_cost => book.production_cost.cents.to_f / 100,
            :amount_printed => book.amount_printed,
            :cost_per_book => book.cost_per_book.cents.to_f / 100,
            :name => book.name,
            :suffix => currency,
            :prefix => "$"
          } #{'id': X, 'printing_date': "<date as usual>", 'printing_cost': X.YY, 'production_cost': X.YY, 'amount_printed': X, 'cost_per_book': X.YY, 'name': "Name", 'prefix': '$', 'suffix': 'CAD'}
        end #books.collect
        
        wrapper = { :total => records.size, :collection => records}
        render :json => wrapper.to_json
      end #format.json
    end #respond_to
  end #publishings_view
  
  def index
    respond_to do |format|
      format.js
      format.json do
        records = process_index
        wrapper = { :total => records.size, :collection => records }
        render :json => wrapper.to_json
      end
    end
  end

  def new
    @book = Book.new
    respond_to do |format|
      format.js
    end
  end
  
  # GET request
  # INPUT params: params[:id]
  # RETURNS
  # format.json => [ {field_name: 'id', field_type: 'integer', value: '1'}, {field_name: 'name', field_type: 'string', value: 'something'}, {field_name: 'internal_id', field_type: 'string', value: 'ABCD'}]
  def show
    respond_to do |format|
      format.json do
        records = @book.attributes_with_field_types
        wrapper = { 'total' => records.size, 'collection' => records}
        render :json => wrapper.to_json
      end
    end
  end

  def async_create
    @book = current_account.books.build(params[:book])
    @book.creator = current_user
    @created = false
    @created = @book.save
    if @created
      product = current_account.products.build(params[:product])
      product.creator_id = current_user.id
      if product.save then @book.product = product end
      
      flash_success :now, "#{@book.name} successfully created"
      render :json => @book.id.to_json
    else
      flash_failure :now, @book.errors.full_messages
      render :json => @book.errors.full_messages.to_json
      # This should return an error message for the panel on failure
      # And should still be status 200
    end
  end

  def edit
    @id = params[:id]
    #@json = get_attributes_with_field_types_as_json_wrapper.to_json
    
    respond_to do |format|
      format.js
    end
  end

  def update
    key = params[:book].keys[0]
    #logger.debug("%%% Before: book.#{key} = #{@book.attributes[key]}")
    @book.attributes = params[:book]
    
    #@book.editor = current_user
    @updated = false
    @updated = @book.save  
    if !@updated
      flash_failure :now, @book.errors.full_messages
    end
    
    # By calling #to_s, Time objects are converted to a
    # string, then that string json-ized.
    render :json => @book.send(key).to_s.to_json
  end

  def destroy
    #pass
  end

  def destroy_collection
    destroyed_items_size = 0
    current_account.books.find(params[:ids].split(",").map(&:strip)).to_a.each do |book|
      next unless book.writeable_by?(current_user)
      destroyed_items_size += 1 if book.destroy
    end

    flash_success :now, "#{destroyed_items_size} book(s) successfully deleted"
    render :json => destroyed_items_size
  end

  def tagged_collection
    @tagged_items_size = 0
    current_account.books.find(params[:ids].split(",").map(&:strip)).to_a.each do |book|
      next unless book.writeable_by?(current_user)
      book.tag_list = book.tag_list + " #{params[:tag_list]}"
      @tagged_items_size += 1 if book.save
    end

    respond_to do |format|
      format.js do
        flash_success :now, "#{@tagged_items_size} books has been tagged with #{params[:tag_list]}"
      end
    end
  end
  
  def async_get_company_names
    respond_to do |format|
      format.js do
        parties = current_account.parties.find(:all, 
          :conditions => ["company_name LIKE ?", %Q`%#{params[:company_name]}%`], 
          :order => "display_name ASC")
        company_names = parties.collect { |party| party.company_name.empty? ? nil : party.company_name }
        records = company_names.uniq.compact.collect { |name| {:company_name => name} }
        wrapper = { :total => records.size, :collection => records }
        render :json => wrapper.to_json
      end
    end
  end
  
  def async_get_party_names_for_company_name
    respond_to do |format|
      format.js do
        company_name = params[:company_name] == '<b>All Companies</b>' ? '' : params[:company_name]
        
        parties = current_account.parties.find(:all, 
          :conditions => ["company_name = ?", %Q`#{company_name}`],
          :order => "display_name ASC")
        party_name_ids = parties.collect { |party| {:name => party.name.to_s, :id => party.id } }
        records = party_name_ids.collect { |kvp| { :party_name => kvp[:name], :id => kvp[:id] } }
        wrapper = { :total => records.size, :collection => records }
        render :json => wrapper.to_json
      end
    end
  end
  
  # POST request
  # INPUT params:
  #   params[:party][:name]
  #   params[:party][:company_name]
  #   params[:party][:notes]
  #   params[:email_address]
  #   params[:party][:rate_per_hr]
  # RETURNS
  # format.js => id of the created party
  def async_add_party
    party = current_account.parties.build(params[:party])
    party.save
    
    email = party.main_email
    email.attributes = {:email_address => params[:email_address]}
    email.save; party.save
    
    render :json => party.id.to_json
  end
  
  # POST request
  # INPUT params:
  # id: the id of the book
  # relation[party_id]: the id of the specified party
  # relation[classification]: type of relations to add, e.g use "Accountant" to add an accountant and "TextPrep" to add a text_prep, etc
  def async_add_relation
    params[:relation][:classification] = generate_classification_for_name params[:relation_name]
    @new_relation = @book.relations.build(params[:relation])
    @added = @new_relation.save
    if @added
      flash_success :now, "New relation added"
    else
      flash_failure :now, @new_relation.errors.full_messages
    end
    
    render :json => parties_for_relation(params[:relation_name]).to_json # this is record.value
  end
  
  def async_get_relation
    records = parties_for_relation(params[:relation_name])
    render :json => {:total => records.size, :collection => records}.to_json
  end
  
  # POST request
  # INPUT params:
  #   id: id of the book
  #   classification: relation type, e.g Accountant, Author, Designer, Editor, etc
  #   ids: a string containing ids of parties
  #   relation_name_sing: singular form of relation name
  # RETURNS
  #   number of relations deleted
  def async_remove_relations_by_ids
    ids = params[:ids].split(",").map(&:strip)
    num_removed_relations = @book.remove_relation(params[:relation_name_sing], ids) 
    render :json => parties_for_relation(params[:relation_name_sing]).to_json # this is record.value
  end

  # GET request
  # INPUT params:
  #   field_name: the field from which to get entries
  # RETURNS
  #   { total: X, collection: [{value: Y}]}
  def async_get_options_for_field_name
    books = current_account.books.find(:all)
    # Find all values under the column in field_name from all Book records 
    options = books.collect { |book| book.send(params[:field_name]).to_s }
    # Reject all blank/null options
    options.reject! { |option| option.nil? }
    records = options.uniq.collect { |option| { :value => option} }
    wrapper = { :total => records.size, :collection => records }
    render :json => wrapper.to_json
  end
  
  # POST request
  # INPUT params:
  #   id: the id of book to duplicate
  #   n: number of duplicates to be made
  # RETURNS
  #   an array of the ids of the new records made as JSON, e.g [1,2,3]
  def duplicate
    book_objects = []
    params[:n].to_i.times do |i|
      book_object = @book.duplicate
      book_object.save
      book_objects << book_object
    end
    render :json => book_objects.map(&:id).to_json
  end
  
  # POST request
  # INPUT params:
  #   id: id of the book
  #   file: the data of the image
  # RETURNS
  #   on success - [{url: '/somewhere.ext', id: X}]
  #   on failure - "Error 1, Error 2"
  def async_upload_image
    picture = current_account.assets.build(:uploaded_data => params[:file]);
    picture.content_type = params[:content_type] if params[:content_type]
    picture.save
    book_view = @book.views.build(:asset_id => picture.id)  
    status = book_view.save
    message_array = picture.errors.full_messages + book_view.errors.full_messages
    
    if status
      render :text => {:success => status, :message => 'Upload Successful!', :records => @book.picture_records, :picture_id => picture.id}.to_json
    else
      render :text => {:success => false, :error => message_array.join(',')}.to_json
    end
    
    #render :text => {:id => picture.id, :success => status, :message => message_array.join(', ')}.to_json
  end
  
  # GET request
  # INPUT params:
  #   id: id of the book
  # RETURNS:
  #   [1,2,3]
  def async_get_image_ids
    render :json => @book.picture_ids.to_json
  end
  
  # POST request
  # INPUT params:
  #   id: id of the book
  #   image_id: id of the image
  # RETURNS:
  #   true / false in json
  def async_destroy_image
    status = false
    view = @book.views.find(:first, :conditions => ["asset_id = ?", params[:image_id]])
    if view
      status = view.destroy
    end
    
    render :json => @book.picture_records.to_json
  end
  
  protected

  def generate_classification_for_name(relationName)
    name = relationName.sub(/s$/, '')
    words = name.split('_')
    words = words.collect { |word| word.capitalize }
    return words.join('')
  end
  
  def parties_for_relation(name)
    parties = @book.send("#{name}")
    # Then fashion records in the appropriate format
    #   [{'id' => X, 'name' => 'Someone', 'company_name' => 'Some Company'}]
    records = parties.collect { |party| { :id => party.id, :name => party.name.to_s, :company_name => party.company_name } }
  end
  
  def get_attributes_with_field_types_as_json_wrapper
    records = @book.attributes_with_field_types
    logger.debug("^^^aloha im here #{records.inspect}")
    wrapper = { 'total' => records.size, 'collection' => records }
    return wrapper
  end
  
  def find_common_books_tags
    @common_tags = current_account.books.tags(:order => "count DESC, name ASC")
  end

  def process_index
    @books = current_account.books.find(:all)
    records = []
    @books.each do |book|
      record = {
        'id' => book.id,
        'name' => book.name,
        'isbn' => book.isbn,
        'language' => book.language
      }
      records.push record
    end
    
    return records
  end

  def find_book
    @book = current_account.books.find(params[:id])
  end

  def convert_cost_params_to_money
    Book::DEFINED_COST_FIELDS.each do |cost_field|
      params[:book]["#{cost_field}_cost"] = params[:book]["#{cost_field}_cost"].to_money if params[:book]["#{cost_field}_cost"]
    end
  end  
end
