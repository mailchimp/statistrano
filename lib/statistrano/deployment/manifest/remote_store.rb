module Statistrano
  module Deployment
    class Manifest

      # manages the manifest file on the remote
      #
      class RemoteStore

        attr_reader :config, :path

        def initialize config
          @config = config
          @path   = config.remote_dir
        end

        def fetch
          fetch_remote_manifest.map { |release| new_release_instance( release ) }
        end

        def update_content string
          config.ssh_session
            .run "touch #{manifest_path} && echo '#{string}' > #{manifest_path}"
        end

        private

          # path to the manifest
          # @return [String]
          def manifest_path
            File.join( path, 'manifest.json' )
          end

          def fetch_remote_manifest
            raw_manifest = config.ssh_session.run "touch #{manifest_path} && cat #{manifest_path}"
            if raw_manifest.success? && !raw_manifest.stdout.empty?
              return JSON.parse( raw_manifest.stdout )
            else
              return []
            end
          end

          def new_release_instance release
            name = release.delete("name")
            release.merge({ repo_url: config.repo_url }) if config.repo_url
            return Release.new( name, config, release )
          end
      end

    end
  end
end