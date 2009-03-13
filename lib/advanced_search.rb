#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module AdvancedSearch
  
  AVAILABLE_MODELS_FOR_SEARCH = [
      "AddressContactRoute",
      "Assignee",
      #"AttachmentAuthorization",
      "Attachment",
      "CommentEstimateLine",
      #"CommentInvoiceLine",
      #"ContactRequestEvent",
      "ContactRequest",
      
      #"ContactRoute",
      "CursorEstimateLine",
      #"EmailAccount",
      "EmailContactRoute",      
      #"EmailEvent",
      "Email",
      #"EstimateEvent",
      
      #"EstimateLine",
      "Estimate",
      #"Event",
      "Feed",
      "ForumPost", 
      "ForumTopic", 
      "Forum",
      #"Geoposition",
      #"InvoiceEvent",
      
      "InvoiceLine", 
      "Invoice",
      "Layout",
      "LinkCategory",
      "LinkContactRoute",
      "Link",
      "Page",
      
      #"PartyPicture", 
      "Party",
      #"PaymentEvent",
      #"Payment",
      "PhoneContactRoute",
      #"Picture",
      #"Pop3EmailAccount",
      "ProductCategory",
      "ProductEstimateLine",
      
      #"ProductInvoiceLine",
      "Product",
      "Recipient",
      "Search",      
      "Tag",
      "Testimonial"]
      #"TodoEvent"
  
  # hash containing pairs of attribute name and models that are not going to be searched on
  # even though those models have the attribute specified
  REJECTED_MODEL = {
    "address" => ["Link", "EmailContactRoute", "LinkContactRoute"],
    "email" => ["Link", "LinkContactRoute"],
    "url" => ["EmailContactRoute"], # has to be the same as web, website_url
    "web" => ["EmailContactRoute"], # has to be the same as url, website_url
    "website_url" => ["EmailContactRoute"] # has to be the same as url, web
  }
  # PLEASE PAY ATTN TO THE SORT_PARAMS ORDERING AS IT DETERMINES THE SORT PRIORITY 
  # AS WELL AS THE ORDER NAMES RETURNED
  # 
  # search_params is an array of search line hashes
  # a search line hash contains subject_name, subject_option, subject_value and subject_exclude as keys
  # subject_exclude does not always exist in a search line hash
  # 
  # sort_params is an array of sort by line hashes
  # a sort by line hash contains order_name and order_mode as keys
  # 
  # returns order_names (sort_params after processed), search results
  # search results is a two dimensional array
  # each array contains 0 to N sort by attributes followed by an extra object at the end
  # an example of a search result array with four sort by attributes ["Party Name", "Party", Time object, Time object, Party object]
  def self.perform_search(search_params, sort_params, options={})
    raise "options[:account] required for Ferret search" unless options[:account]

    no_search_param = true
    for searchp in search_params
      no_search_param = false if !searchp[:subject_name].blank? && !searchp[:subject_value].blank?
    end
    return [], [] if no_search_param
    
    # initialize SearchLine objects
    array_of_search_lines = []
    #RAILS_DEFAULT_LOGGER.debug("=======> Search params = #{search_params.inspect}")
    #RAILS_DEFAULT_LOGGER.debug("=======> Sort params = #{sort_params.inspect}")
    search_by_type = []
    for search_line in search_params.uniq
      if !search_line[:subject_name].blank? && !search_line[:subject_value].blank?
        array_of_search_lines << SearchLine.new(search_line.dup)
        search_by_type << search_line[:subject_value] if search_line[:subject_name].downcase == "type" 
      end 
    end

    #RAILS_DEFAULT_LOGGER.debug("Array of search lines = #{array_of_search_lines.inspect}")
    # processing Tag search params
    # obtain tag search params from the array of search line objects and remove them from the array
    tag_search_lines = []
    for search_line in array_of_search_lines
      if search_line.subject =~ /tags?/i || search_line.subject =~ /tag\sname/i
        search_line_mod = SearchLine.new(search_line.get_hash.dup)
        search_line_mod.subject = "Name"
        tag_search_lines << search_line_mod
      end
    end
    array_of_search_lines.delete_if {|x| x.subject =~ /tags?|tag\sname/i }
    #RAILS_DEFAULT_LOGGER.debug("Array of search lines = #{array_of_search_lines.inspect}")
    
    tag_names = []
    unless tag_search_lines.blank?
      #RAILS_DEFAULT_LOGGER.debug("tag_search_lines = #{tag_search_lines.inspect}")      
      find_conditions = SearchLinesToFindConditionsMapper::map_to_find_conditions("Tag", tag_search_lines, options)
      #RAILS_DEFAULT_LOGGER.debug("find_conditions = #{find_conditions.inspect}")
      tag_names += Tag.find(:all, :conditions => find_conditions).map(&:name)
    end
    tag_names.uniq!    
    #RAILS_DEFAULT_LOGGER.debug("tag_names = #{tag_names.inspect}")
    
    models_to_be_searched = AVAILABLE_MODELS_FOR_SEARCH
    # change models to be searched if there are searches on type
    # if there are multiple searches by type, only the first one is accounted  
    if !search_by_type.blank?
      for m in AVAILABLE_MODELS_FOR_SEARCH
        models_to_be_searched = m if search_by_type.first.downcase == m.downcase
      end
    end
    search_result_before_sort = []
    #RAILS_DEFAULT_LOGGER.debug("MODELS = #{models_to_be_searched.inspect}")
    
    # check search line attributes and remove models to be searched if there is any specified rejection
    for search_line in array_of_search_lines
      models_to_be_searched -= REJECTED_MODEL[search_line.attribute] if REJECTED_MODEL[search_line.attribute]
    end
    
    for m in models_to_be_searched
      find_conditions = SearchLinesToFindConditionsMapper::map_to_find_conditions(m, array_of_search_lines, options)
      #RAILS_DEFAULT_LOGGER.debug("====> Model to be searched = #{m}")
      #RAILS_DEFAULT_LOGGER.debug("====> Find conditions = #{find_conditions}")
      result = []
      if tag_search_lines.blank?
        result = m.constantize.find(:all, :conditions => find_conditions) unless find_conditions.blank?
      elsif !tag_search_lines.blank? && m.constantize.respond_to?(:find_tagged_with) && !tag_names.blank?
        if find_conditions.blank?
          result = m.constantize.find_tagged_with(:any => tag_names)
        else
          result = m.constantize.find_tagged_with(:any => tag_names, :conditions => find_conditions)
        end
      end      
      search_result_before_sort += result
    end
    return [], [] if search_result_before_sort.blank?
    
    processed_sort_params = []
    for sortp in sort_params.dup.uniq
      #RAILS_DEFAULT_LOGGER.debug("Sort params = #{sortp.inspect}")
      if !sortp[:order_name].blank?
        unless processed_sort_params.include?({:order_name => sortp[:order_name], :order_mode => "ASC"}) || processed_sort_params.include?({:order_name => sortp[:order_name], :order_mode => "DESC"}) 
          processed_sort_params << {:order_name => sortp[:order_name].downcase.gsub(" ", "_"), :order_mode => sortp[:order_mode]}
        end 
      end
    end 
    #RAILS_DEFAULT_LOGGER.debug("Processed sort params = #{processed_sort_params.inspect}")
    
    # add subject name as a sort params with default order mode (ASC) if there is no sort order line specified for the particular subject name
    for e in array_of_search_lines
      processed_sort_params << {:order_name => e.attribute, :order_mode => "ASC"} unless processed_sort_params.include?({:order_name => e.attribute, :order_mode => "ASC"}) || processed_sort_params.include?({:order_name => e.attribute, :order_mode => "DESC"})
    end
    
    sort_start_point = 0
    main_identifier_pos = processed_sort_params.index({:order_name => "main_identifier", :order_mode => "ASC"}) || processed_sort_params.index({:order_name => "main_identifier", :order_mode => "DESC"})
    type_pos = processed_sort_params.index({:order_name => "type", :order_mode => "ASC"}) || processed_sort_params.index({:order_name => "type", :order_mode => "DESC"})
    
    #RAILS_DEFAULT_LOGGER.debug("main pos = #{main_identifier_pos.inspect}")    
    #RAILS_DEFAULT_LOGGER.debug("type pos = #{type_pos.inspect}")    
    if main_identifier_pos.nil? && type_pos.nil?
      #RAILS_DEFAULT_LOGGER.debug("BOTH ARE NIL")
      processed_sort_params.insert(0, {:order_name => "main_identifier", :order_mode => "ASC"})
      processed_sort_params.insert(1, {:order_name => "type", :order_mode => "ASC"})
      # sort_start_point is 0, no change
    elsif !main_identifier_pos.nil? && type_pos.nil?
      #RAILS_DEFAULT_LOGGER.debug("MAIN IS NOT NIL")      
      processed_sort_params << {:order_name => "type", :order_mode => "ASC"}
      # sort_start_point is 0, no change
    elsif main_identifier_pos.nil? && !type_pos.nil?
      #RAILS_DEFAULT_LOGGER.debug("TYPE IS NOT NIL")      
      processed_sort_params.insert(0, {:order_name => "main_identifier", :order_mode => "ASC"})
      sort_start_point = 1                
    end    
    
    # appending updated_at and created_at when necessary
    unless processed_sort_params.include?({:order_name => "updated_at", :order_mode => "ASC"}) || processed_sort_params.include?({:order_name => "updated_at", :order_mode => "DESC"})
      processed_sort_params << {:order_name => "updated_at", :order_mode => "ASC"} if processed_sort_params.size < 4
    end
    unless processed_sort_params.include?({:order_name => "created_at", :order_mode => "ASC"}) || processed_sort_params.include?({:order_name => "created_at", :order_mode => "DESC"})
      processed_sort_params << {:order_name => "created_at", :order_mode => "ASC"} if processed_sort_params.size < 4
    end

    # generating array of sort order modes
    sort_order_modes = []
    for processed_sortp in processed_sort_params
      if processed_sortp[:order_mode] == "ASC"
        sort_order_modes << true
      else
        sort_order_modes << false
      end
    end

    #RAILS_DEFAULT_LOGGER.debug("Updated processed sort params = #{processed_sort_params.inspect}")
    search_result_added = []
    for e in search_result_before_sort
      a = []
      for processed_sortp in processed_sort_params
        a << SortOrderNameToClassAttributeValueMapper::get_order_name_value(e, processed_sortp[:order_name])
      end
      a << e
      search_result_added << a
    end    
    #RAILS_DEFAULT_LOGGER.debug("search_result_added = #{search_result_added.inspect}")
    
    order_names = []
    for processed_sortp in processed_sort_params
      order_names << processed_sortp[:order_name]
    end
    #RAILS_DEFAULT_LOGGER.debug("order_names = #{order_names.inspect}")
    
    # make sure all values in a column are of the same type
    for i in 0..(order_names.size-1)
      all_same_type = true
      type = search_result_added[0][i].class.name
      for e in search_result_added
        all_same_type = false if e[i].class.name != type
        break if !all_same_type
      end
      if !all_same_type
        for e in search_result_added
          e[i] = e[i].to_s
        end
      end
    end    
    
    #RAILS_DEFAULT_LOGGER.debug("search_result_added AFTER = #{search_result_added.inspect}")
    return order_names, SortObjectsByArrayElements::execute_sort(search_result_added, sort_order_modes, sort_start_point)
  end
  
  module AutoCompleteListToAttributesMapper
    MULTIPLE_MAP_ADD = {
      "address" => ["line1", "line2", "line3", "zip", "state", "country"],
      "email" => ["address"],
      # main identifier does not exist as a column in any table
      "main_identifier" => [
         "address",
         "amount",
         "body",
         "city",
         "comment",
         "company_name", 
         "country",
         "description", 
         "display_name",
         "extension",
         "feed_url",
         "filename", 
         "first_name",
         "geometry", 
         "last_name",
         "last_updated_at",
         "latitude",
         "line1", "line2", "line3",
         "longitude",
         "middle_name",
         "name",
         "no",
         "number",
         "product_no",
         "reason",
         "state",
         "status",
         "subject",
         "testified_on", 
         "title",
         "updated_at",
         "url",
         "zip"],
      "name" => ["title", "display_name", "first_name", "middle_name", "last_name", "feed_url"],
      "url" => ["address", "url"], # has to be the same as web, website_url
      "web" => ["address", "url"], # has to be the same as url, website_url
      "website_url" => ["address", "url"] # has to be the same as url, web
    }

    def self.mapped_to(class_name, key)
      #RAILS_DEFAULT_LOGGER.debug(">>>>>>>>>>AutoCompleteListToAttributesMapper<<<<<<<<<<<<<<")
      mapped_attributes = [key]
      mapped_attributes += MULTIPLE_MAP_ADD[key] unless MULTIPLE_MAP_ADD[key].nil?
      mapped_attributes.uniq!
      #RAILS_DEFAULT_LOGGER.debug("mapped_attributes = #{mapped_attributes.inspect}")
      mapping_result = []
      for m in mapped_attributes
        mapping_result << m if ::AdvancedSearch::model_has_attribute?(class_name, m)
      end
      #RAILS_DEFAULT_LOGGER.debug("mapping_result = #{mapping_result.inspect}")
      return mapping_result
    end
  end
  
  module SearchLinesToFindConditionsMapper
    def self.map_to_find_conditions(object_class_name, search_lines, options={})
      conditions = []
      table_name = object_class_name.constantize.table_name
      conditions << "#{table_name}.account_id = #{options[:account].id}" if object_class_name.constantize.columns.map(&:name).include?("account_id")
      for search_line in search_lines
        mapped_attributes = AutoCompleteListToAttributesMapper::mapped_to(object_class_name, search_line.attribute)
        mapped_conditions = []
        for mm in mapped_attributes
          s = SearchLine.new(search_line.get_hash.merge({:subject_name => mm}))
          mapped_conditions << "#{table_name}.#{s.search_condition}"
        end
        if mapped_conditions.blank?
          return ""
        else
          string_mapped_conditions = "(" << mapped_conditions.join(" OR ") << ")" 
          string_mapped_conditions = "NOT #{string_mapped_conditions}" if search_line.exclude?
          conditions << string_mapped_conditions
        end
      end
      return conditions.join(" AND ")
    end
  end

  module SortOrderNameToClassAttributeValueMapper
    def self.get_order_name_value(object, order_name)
      #RAILS_DEFAULT_LOGGER.debug("GET ORDER NAME VALUE = #{object.class.name} ==> #{order_name}")
      value = [] 
      mapped_attributes = AutoCompleteListToAttributesMapper::mapped_to(object.class.name, order_name)
      for ma in mapped_attributes
        value << object.send(ma.to_sym) rescue next
      end
      result = nil
      value = value.delete_if {|e| e == nil || e == ""}
      #RAILS_DEFAULT_LOGGER.debug("VALUE BEFORE IF BLOCK = #{value.inspect} BLANK? #{value.blank?}")
      if value.blank?
        if order_name =~ /_at/
          result = Time.at(0)
        else
          result = ""
        end
      else
        result = value.first
      end
      if order_name == "main_identifier"
        result = object.main_identifier rescue ""
      elsif order_name == "type"
        result = object.class.name
      end
      #RAILS_DEFAULT_LOGGER.debug("VALUE AFTER IF BLOCK = #{value.inspect}")
      #RAILS_DEFAULT_LOGGER.debug("RESULT IS = #{result}")      
      return result
    end
  end
  
  class SearchLine
    def initialize(hash)
      @line = hash
    end
    
    def get_hash
      @line
    end
    
    def subject
      return @line[:subject_name].to_s
    end
    
    def subject=(new_subject)
      @line[:subject_name] = new_subject 
    end
    
    def option
      return @line[:subject_option].to_s
    end
    
    def value
      return @line[:subject_value].to_s
    end
    
    def attribute
      return @line[:subject_name].downcase.gsub(" ", "_")
    end
    
    def exclude?
      return true if @line[:subject_exclude]
      false
    end
    
    def search_condition
      return "" if self.attribute.blank? || self.value.blank?
      temp = "#{self.attribute} "
      case self.option
      when /contain/i
        temp << "LIKE '%#{value}%'"
      when /start/i
        temp << "LIKE '#{value}%'"
      when /end/i
        temp << "LIKE '%#{value}'"
      when /equal/i
        temp << "LIKE '#{value}'"
      else
        temp << "LIKE '%#{value}%'"
      end
      return temp
    end
    
    def self.get_subjects_of_collection(search_lines)
      subjects = []
      for e in search_lines
        subjects << e.subject unless e.subject.blank? || e.value.blank?
      end
      return subjects 
    end
    
    def self.get_search_conditions_of_collection(search_lines)
      conditions = []
      for e in search_lines
        conditions << e.search_condition
      end
      return conditions 
    end
  end

  # PERFORMANCE IS CRAP
  module SortObjectsByArrayElements
    # each entry in array_to_be_sorted is an array
    # an entry contains sort elements (ordered by sorting priority) plus an extra element at the end
    # an entry example [sort_elem0, sort_elem1, sort_elem2, ..., sort_elemN, object]
    # sort_order_modes contains sort order modes of each sort elem
    # true is order by ascending, false is order by descending
    # start_point determines from which sort_elem the sorting process starts
    def self.execute_sort(array_to_be_sorted, sort_order_modes, start_point)
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "=======> I am in sort module")     
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "array_to_be_sorted SIZE = #{array_to_be_sorted.size} ; CONTAIN = #{array_to_be_sorted.inspect}")     
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "sort_order_modes = #{sort_order_modes.inspect}")     
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "start_point = #{start_point}")     
      # check if all objects of a particular column are of type String
      all_string_type = true
      for e in array_to_be_sorted
          all_string_type = false if e[start_point].class.name != "String"
      end
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "All string type = #{all_string_type}")           
      sorted_array = []
      if all_string_type
        sorted_array = array_to_be_sorted.sort {|e,f| e[start_point].casecmp(f[start_point])}
      else
        sorted_array = array_to_be_sorted.sort_by {|e| e[start_point]}
      end
      sorted_array.reverse! if !sort_order_modes[start_point] # reverse self
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "Sorted array = #{sorted_array.inspect}")           
      #for a in sorted_array
      #  RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "Element = #{a.inspect}")           
      #end
      # return sorted array immediately if it is the last sorting point or if sorted array size is one
      if sorted_array.size < 2 || start_point == sort_order_modes.size-1
        #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "<======= SIZE #{sorted_array.size}, RETURN = #{sorted_array.inspect}")               
        return sorted_array 
      end 
      
      # go through all elements in the sorted array up to the second last element
      i = 0
      while i < (sorted_array.size-1)
        stop_index = i
        #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "Right before inner while loop, value of i = #{i}")
        a = sorted_array[i].fetch(start_point)
        b = sorted_array[stop_index+1].fetch(start_point)
        # downcase elements to be compared if all objects of a particular column in sorted array are of String type
        if all_string_type
          a = a.downcase
          b = b.downcase
        end
        # increment stop index if elements to be compared are equal and proceed to the next comparison
        # break the comparison operation if stop index is equal to the last index in the sorted array
        while a == b
          #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "sorted_array[i] = #{sorted_array[i].inspect}")
          #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "sorted_array[stop_index+1] = #{sorted_array[stop_index+1].inspect}")          
          stop_index += 1
          break if stop_index == sorted_array.size-1
          a = sorted_array[i].fetch(start_point)
          b = sorted_array[stop_index+1].fetch(start_point)
          if all_string_type
            a = a.downcase
            b = b.downcase
          end
        end
        #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "value of i = #{i} ; stop_index = #{stop_index}")          
        # sort elements with equal sorting attribute by the next sorting point
        if stop_index > i
          array_need_to_be_sorted = sorted_array[i..stop_index]
          front_side = (i != 0) ? sorted_array[0..(i-1)] : []
          back_side = sorted_array[(stop_index+1)..-1]
          #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "array_need_to_be_sorted SIZE = #{array_need_to_be_sorted.size}, CONTAIN = #{array_need_to_be_sorted.inspect}")          
          #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "front_side SIZE = #{front_side.size}, CONTAIN = #{front_side.inspect}")          
          #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "back_side SIZE = #{back_side.size}, CONTAIN = #{back_side.inspect}")          
          #if start_point < sort_order_modes.size-1
            sorted_array = front_side + self.execute_sort(array_need_to_be_sorted, sort_order_modes, start_point + 1) + back_side 
          #end
          i = stop_index
        end
        i += 1
        #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "After if conditions, value of i = #{i}")
        #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "#{i} < #{sorted_array.size-1} VALUE #{i < (sorted_array.size-1)}")
      end
      #RAILS_DEFAULT_LOGGER.debug(" "*start_point*10 << "<======= I am almost out of sort module, SIZE = #{sorted_array.size},RETURN = #{sorted_array.inspect}")           
      return sorted_array
    end
  end

  def self.get_auto_complete_list
    auto_complete_list = self.get_all_column_contents.map {|e| e.humanize}
    return auto_complete_list
  end
    
protected
  def self.model_has_attribute?(model, attribute)
    return true if model.constantize.content_columns.map(&:name).index(attribute)
    return false    
  end
  
  def self.get_all_column_contents
    all_column_contents = []
    for m in AVAILABLE_MODELS_FOR_SEARCH
      all_column_contents += m.constantize.content_columns.map(&:name)
    end
    all_column_contents += ["type", "main_identifier", "web", "tag", "tag_name"] 
    all_column_contents.uniq!
    all_column_contents = all_column_contents.sort
    return all_column_contents
  end
end

