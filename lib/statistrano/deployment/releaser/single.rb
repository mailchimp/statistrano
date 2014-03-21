module Statistrano
  module Deployment
    module Releaser

      class Single
        extend ::Statistrano::Config::Configurable

        options :remote_dir, :local_dir

        def initialize options={}
          config.options.each do |opt,val|
            config.send opt, options.fetch(opt,val)
          end

          check_required_options :remote_dir, :local_dir
        end

        def create_release remote
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
            File.join( remote_overridable_config(:remote_dir, remote) )
          end

          def remote_overridable_config option, remote
            (remote && remote.config.public_send(option)) || config.public_send(option)
          end

      end

    end
  end
end