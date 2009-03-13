#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Backends
      module S3Backend
        
        def set_storage_access
          contents = nil
          contents = File.open(create_temp_file.path, "rb").read
          S3Object.store(
            full_filename,
            contents, 
            bucket_name,
            :content_type => content_type,
            :access => self.private ? :private : :public_read
          )
          true
        rescue AWS::S3::NoSuchKey
          RAILS_DEFAULT_LOGGER.warn(" ==> Warning: AWS::S3::NoSuchKey for asset id:#{self.id}")
        end
        
        protected
          def rename_file
            return unless @old_filename && @old_filename != filename
            
            old_full_filename = File.join(base_path, @old_filename)

            S3Object.rename(
              old_full_filename,
              full_filename,
              bucket_name,
              :access => self.private ? :private : :public_read
            )

            @old_filename = nil
            true
          end

          def save_to_storage
            if save_attachment?
              contents = nil
              contents = temp_path ? File.open(temp_path, "rb").read : temp_data
              S3Object.store(
                full_filename,
                contents, 
                bucket_name,
                :content_type => content_type,
                :access => self.private ? :private : :public_read
              )
            end

            @old_filename = nil
            true
          end
      end
    end
  end
end

    
