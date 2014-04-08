module Statistrano
  module Deployment
    class Manifest

      attr_reader :remote_dir, :remote, :file

      def initialize remote_dir, remote
        @remote_dir = remote_dir
        @remote     = remote
        @file       = Remote::File.new remote_path, remote
      end

      # return an array of records from the manifest
      # they are processed to all have symbolized keys
      #
      def data
        @_data ||= Array( JSON.parse(raw) ).map { |h| Util.symbolize_hash_keys(h) }
      rescue JSON::ParserError => e
        Log.error "manifest on #{remote.config.hostname} had invalid JSON\n",
                  e.message
      end

      # push data into the manifest array updating a
      # record if it matches with the `match_key`
      #
      # not that if you have used the `push` method previously
      # all duplicates with the matching key **will** be removed
      #
      def put data, match_key
        remove_if { |i| i[match_key] == data[match_key] }
        push data
      end

      # pushes a data has into the manifest's array
      #
      def push new_data
        unless new_data.respond_to? :to_json
          raise ArgumentError, "data must be serializable as JSON"
        end

        data << Util.symbolize_hash_keys(new_data)
      end

      # pass a condition to remove records from the
      # manifest if it returns true
      #
      # example:
      #   to remove all records with the name "name"
      #
      #   manifest.remove_if |release|
      #     release[:name] == "name"
      #   end
      #
      def remove_if &condition
        data.delete_if do |item|
          condition.call item
        end
      end

      # update the manifest using the data
      # currently stored on the object
      #
      def save!
        file.update_content! serialize
      end

      private

        def raw
          content = file.content
          if content.empty?
            return "[]"
          else
            return content
          end
        end

        def serialize data=data
          data.to_json
        end

        def remote_path
          File.join( remote_dir, 'manifest.json' )
        end

    end
  end
end