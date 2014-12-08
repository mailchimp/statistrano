module Statistrano
  module Deployment
    module Releaser

      class Single

        attr_reader :release_name

        def initialize
          @release_name = Time.now.to_i.to_s
        end

        def create_release remote, build_data={}
          setup remote
          rsync_to_remote remote
        end

        def setup remote
          Log.info   "Setting up the remote"
          remote.run "mkdir -p #{remote_path(remote)}"
        end

        def rsync_to_remote remote
          resp = remote.rsync_to_remote local_path(remote), remote_path(remote)
          unless resp.success?
            abort()
          end
        end

        private

          def local_path remote
            File.join( Dir.pwd, remote.config.local_dir )
          end

          def remote_path remote=nil
            if remote.config.respond_to?(:public_dir) && remote.config.public_dir
              return File.join( remote.config.remote_dir, remote.config.public_dir )
            else
              return remote.config.remote_dir
            end
          end

      end

    end
  end
end
