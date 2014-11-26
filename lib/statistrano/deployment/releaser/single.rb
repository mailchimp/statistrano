module Statistrano
  module Deployment
    module Releaser

      class Single
        extend ::Statistrano::Config::Configurable

        options :remote_dir, :local_dir,
                # optional options
                :public_dir

        attr_reader :release_name

        def initialize options={}
          config.options.each do |opt,val|
            config.send opt, options.fetch(opt,val)
          end

          check_required_options :remote_dir, :local_dir
          @release_name = Time.now.to_i.to_s
        end

        def create_release remote, build_data={}
          setup remote
          rsync_to_remote remote
        end

        def setup remote
          Log.info "Setting up the remote"
          remote.run "mkdir -p #{remote_path(remote)}"
        end

        def rsync_to_remote remote
          resp = remote.rsync_to_remote local_path(remote), remote_path(remote)
          unless resp.success?
            abort()
          end
        end

        private

          def check_required_options *opts
            opts.each do |opt|
              raise ArgumentError, "a #{opt} is required" unless config.public_send(opt)
            end
          end

          def local_path remote=nil
            File.join( Dir.pwd, remote_overridable_config(:local_dir, remote) )
          end

          def remote_path remote=nil
            path = File.join( remote_overridable_config(:remote_dir, remote) )
            if config.respond_to?(:public_dir)
              path_with_public_dir = remote_overridable_config(:public_dir, remote)
              path = File.join( path, path_with_public_dir ) if path_with_public_dir
            end

            return path
          end

          def remote_overridable_config option, remote
            (remote && remote.config.respond_to?(option) && remote.config.public_send(option)) || config.public_send(option)
          end

      end

    end
  end
end
