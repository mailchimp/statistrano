module Statistrano
  module Deployment
    class MultiTarget

      class Manifest

        attr_reader :remote_dir, :target

        def initialize remote_dir, target
          @remote_dir = remote_dir
          @target     = target
        end

        def data
          @_data ||= Array( JSON.parse(raw) ).map { |h| Util.symbolize_hash_keys(h) }
        rescue JSON::ParserError => e
          LOG.error "manifest on #{target.config.remote} had invalid JSON\n" +
                    "===\n#{e.message}"
        end

        def push new_data
          unless new_data.respond_to? :to_json
            raise ArgumentError, "data must be serializable as JSON"
          end

          data << Util.symbolize_hash_keys(new_data)
        end

        def remove_if &condition
          data.delete_if do |item|
            condition.call item
          end
        end

        def save!
          # saves the current data state to remote
        end

        private

          def raw
            resp = target.run "cat #{remote_path}"
            if resp.success?
              resp.stdout
            else
              "[]"
            end
          end

          def serialize data={}
            # serialize hash
          end

          def remote_path
            File.join( remote_dir, 'manifest.json' )
          end

      end

    end
  end
end