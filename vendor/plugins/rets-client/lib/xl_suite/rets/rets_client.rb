module XlSuite
  module Rets
    class RetsClient
      class LookupFailure < StandardError; end

      def initialize(rets)
        @rets = rets
      end

      # Each search result is yielded, if a block is given.
      # Raises LookupFailure in case of non-success.
      def search(resource, klass, query, options={})
        params = {}
        params["Limit"] = options[:limit].to_i if options[:limit]
        @rets.search(resource, klass, query, params) do |txn|
          if txn.success? then
            if block_given? then
              txn.data.map do |result|
                yield(result)
              end
            else
              txn.data
            end
          else
            raise LookupFailure, "Unable to search RETS server data: #{txn.reply_code} #{txn.reply_text}"
          end
        end
      end

      # Yields all metadata as a block, or returns it.
      # Raises LookupFailure in case of non-success.
      def lookup(klass, id)
        @rets.get_metadata("METADATA-#{klass.to_s.upcase}", id) do |txn|
          if txn.success? then
            if block_given? then
              yield txn.data
            else
              return txn.data
            end
          else
            raise LookupFailure, "Unable to lookup data from the RETS server: #{txn.reply_code} #{txn.reply_text}"
          end
      	end
      end

      def get_photos(type, id) #:yields: image_binary_data, hash_of_options
        raise ArgumentError, "\#get_photos requires a block to yield the image data to" unless block_given?
        @rets.get_object(type.to_s.capitalize, "Photo", "#{id}:*", 0) do |object|
          yield object.data, object.type
        end
      end
    end
  end
end
