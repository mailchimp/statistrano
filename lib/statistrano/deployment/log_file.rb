module Statistrano
  module Deployment
    class LogFile

      attr_reader :resolved_path, :remote, :file

      def initialize path, remote
        @remote        = remote
        @resolved_path = resolve_path path
        @file          = Remote::File.new @resolved_path, remote
      end

      def append! log_entry
        file.append_content! log_entry.to_json
      end

      def last_entry
        entries(1).last || {}
      end

      def tail length=10
        entries(length)
      end

      private

        def entries length=10
          entries = file.content.split("\n") || []
          entries.reverse[0...length].map do |e|
            Util.symbolize_hash_keys( JSON.parse(e) )
          end
        end

        def resolve_path path
          if path.start_with? '/'
            path
          else
            File.join( remote.config.remote_dir, path )
          end
        end

    end
  end
end
