module ActiveRecord
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Adds tagging to your model
        #
        # Example:
        #
        #    class Article < ActiveRecord::Base
        #      acts_as_taggable
        #    end
        def acts_as_taggable(options = {})
          options = options.dup
          write_inheritable_attribute(:acts_as_taggable_options, {
            :taggable_type => ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s,
            :from => options.delete(:from)
          })

          class_inheritable_reader :acts_as_taggable_options

          has_many :taggings, :as => :taggable, :dependent => :destroy
          has_many :tags, {:through => :taggings, :order => 'LOWER(tags.name)'}.merge(options)
          
          after_save :update_taggings

          include ActiveRecord::Acts::Taggable::InstanceMethods
          extend ActiveRecord::Acts::Taggable::SingletonMethods
        end
      end

      module SingletonMethods
        # Returns an array of taggables based on the tags passed
        # You can search for all tags or any tags by passing the list of tags
        # with the :all or :any key.
        #
        # Example:
        #
        #     Article.find_tagged_with(:all => ['rails', 'programming'])
        #     Article.find_tagged_with(:any => ['rails', 'programming'])
        #
        # This method will also work with associations.  Assuming you have different
        # Blog instances, you can find Articles within a single blog.
        #
        # Example:
        #
        #    @my_blog.articles.find_tagged_with(:any => ['gardening'])
        #    @her_blog.articles.find_tagged_with(:any => ['programming'])
        #
        # Searching for taggables can also be refined by passing the following:
        #
        #  <tt>:conditions</tt>:  specify results on "table_name", tags, and taggings
        #  <tt>:limit</tt>:  limit the number of items to return
        #  <tt>:order</tt>:  order the results
        #  <tt>:joins</tt>:  join with other tables
        #
        # Example:
        #
        #     Article.find_with_tagged(:any => ['rails'], :conditions => "articles.created_at > '2006-01-01')
        #     Article.find_with_tagged(:any => ['rails'], :limit => 5)
        #     Article.find_with_tagged(:any => ['rails'], :order => 'articles.position')
        #
        def find_tagged_with(options={})
          if Array === options
            # Depreciated interface
            options = { :any => options }
          end

          raise ArgumentError, "options must be a Hash" unless options.kind_of?(Hash)

          options = options.dup
          any, all = options.delete(:any), options.delete(:all)
          tags = escape_tags(any || all)

          return [] if tags.blank?

          select_option = case options[:select]
            when String
              options[:select] << ", COUNT(tags.id) AS count"  
            when Array
              options[:select] << "COUNT(tags.id) AS count"
            when nil
              "#{table_name}.*, COUNT(tags.id) AS count"
            end
          
          find :all, options.merge({
              :select => select_option,
              :from => "taggings",
              :joins => "JOIN #{table_name} ON #{table_name}.#{primary_key} = taggings.taggable_id
                         AND taggings.taggable_type = '#{acts_as_taggable_options[:taggable_type]}'
                         LEFT OUTER JOIN tags ON tags.id = taggings.tag_id
                         AND LOWER(tags.name) IN (#{tags.join(',')})",
              :group => "#{table_name}.#{primary_key}
                         #{"HAVING count = #{tags.length}" unless all.nil? }
                         #{"HAVING count > 0" unless any.nil?}",
              :order => options[:order] || "#{table_name}.#{primary_key}"
            })
        end

        def count_tagged_with(options={})
          options = options.dup
          any, all = options.delete(:any), options.delete(:all)
          tags = escape_tags(any || all)

          return 0 if tags.blank?

          Tagging.find(:all, options.merge({
              :select => "COUNT(*) count_all, COUNT(tags.id) AS count",
              :joins => "JOIN #{table_name} ON #{table_name}.#{primary_key} = taggings.taggable_id
                         AND taggings.taggable_type = '#{acts_as_taggable_options[:taggable_type]}'
                         LEFT OUTER JOIN tags ON tags.id = taggings.tag_id
                         AND LOWER(tags.name) IN (#{tags.join(',')})",
              :group => "#{table_name}.#{primary_key}
                         #{"HAVING count = #{tags.length}" unless all.nil? }
                         #{"HAVING count > 0" unless any.nil?}",
              :order => options[:order] || "#{table_name}.#{primary_key}"
            })).size
        end

        # Returns an array of tag objects used for the model
        #
        # Example:
        #
        #    Article.tags
        #    Article.tags :limit => 20, :order => 'count'
        #    Article.tags :conditions => "articles.created_at > '2006-01-01'"
        #    @my_blog.articles.tags
        #    @my_blog.articles.tags.collect { |tag| tag.name }.join(', ')
        #
        def tags(options={})
          Tag.with_scope :find => {:conditions => scope(:find, :conditions)} do
            Tag.find :all, options.merge({
                :select => 'tags.*, COUNT(tags.id) AS count',
                :from   => 'tags',
                :joins  => "JOIN taggings ON taggings.taggable_type = '#{acts_as_taggable_options[:taggable_type]}'
                            AND taggings.tag_id = tags.id
                            LEFT OUTER JOIN #{table_name} ON #{table_name}.#{primary_key} = taggings.taggable_id",
                :order => options[:order] || 'LOWER(tags.name)',
                :group => 'tags.id, tags.name'
              })
          end
        end

        def tags_like(name)
          tags(:conditions => ["tags.name LIKE ?", "#{name}%"])
        end

        # Returns an array of tag objects related shared model tags
        #
        # Example:
        #
        #     @article1.tag_with "one, two"
        #     @article2.tag_with "two, five, three"
        #     Article.find_related_tags(['one']) => two
        #     Article.find_related_tags(['two']) => one, five, three
        #     Article.find_related_tags(['two'], :conditions => "tags.name != 'five') => one, three
        #     Article.find_related_tags([]) => []
        #
        def find_related_tags(list, options={})
          tags = escape_tags(list).join(',')
          return [] if tags.blank?

          related = find_tagged_with(:any => list)
          return [] if related.blank?

          related_ids = related.map(&:id).map(&:to_s).join(', ')

          Tag.find :all, options.merge({
            :select => 'tags.*, COUNT(tags.id) AS count',
            :from   => 'tags',
            :joins  => "JOIN taggings ON taggings.taggable_type = '#{acts_as_taggable_options[:taggable_type]}'
                        AND  taggings.taggable_id IN (#{related_ids})
                        AND  taggings.tag_id = tags.id",
            :order => options[:order] || 'count DESC, tags.name',
            :group => "tags.id, tags.name HAVING count > 0 AND tags.name NOT IN (#{tags})"
          })
        end

      protected
        def escape_tags(list)#:nodoc:
          list.map { |t| t.to_s.strip.downcase }.
            reject { |t| t.blank? }.
            uniq.
            map { |t| "'#{connection.quote_string(t)}'" }
        end
      end

      module InstanceMethods
        # Tags the model with a single tag.  If the :from parameter is used
        # then the tag will be selected from that collection.
        #
        # Returns the tag instance used for the tag name, either a new tag
        # or a tag found from a previous tagging.
        #
        # This method does not check for duplicates.
        #
        # Example:
        #
        #    @article.tag 'cool'
        #    @article.tag 'duplicate' unless @article.tags.include? 'duplicate'
        #
        def tag(name)
          raise ArgumentError, "No tag name specified" if name.blank?

          if acts_as_taggable_options[:from]
            send(acts_as_taggable_options[:from]).tags.find_or_create_by_name(name).on(self).tag
          else
            root = self.respond_to?(:account) ? self.account.tags : Tag
            root.find_or_create_by_name(name).on(self)
          end
        end

        # Parses and tags this object with the string of tags passed.  Returns the
        # reloaded tags collection.  Commas are ignored and tags with spaces need
        # to be quoted.
        #
        # Example:
        #
        #    @article.tag_with "one two three"
        #    @article.tag_with "one, two, three"
        #    @article.tag_with "three, 'four and one half'"
        #    @article.tag_with "three \"four and one half\""
        def tag_with(list)
           Tag.transaction do
            taggings.reload if taggings.blank?
            taggings.destroy_all
            Tag.parse(list).each { |name| tag(name) }
            tags(true)
           end
        end

        # Returns a string of tag names, comma seperated and quoted if necessary
        def tag_list
          list = @tag_list ? @tag_list.collect { |tag| (tag.include?(' ') ? "'#{tag}'" : tag) } : tags(true).collect { |tag| (tag.name.include?(' ') ? "'#{tag.name}'" : tag.name) }
          list.join(', ')
        end

        # Accepts a string of tags used in tag_with, returns the new string of tag names
        def tag_list=(list)
          @tag_list = Tag.parse(list)
          tag_list
        end
        
        def remove_tags(list)
          list = Tag.parse(list)
          @tag_list = tags(true).reject{|t|list.include?(t.name)}.map(&:name)
          tag_list
        end
        
      protected
        def update_taggings
          tag_with(@tag_list) if @tag_list
          true
        end
      end
    end
  end
end
