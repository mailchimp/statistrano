module Statistrano
  module Deployment
    class MultiTarget

      # a target is a databag of config specific for an
      # individual target for a MultiTarget deployment
      # including it's own ssh connection to it's remote
      #
      class Target
        extend ::Statistrano::Config::Configurable
        options :remote, :user, :password, :keys, :forward_agent

        # included to allow override in Releaser,
        # generally these should not be used
        options :remote_dir, :local_dir,
                :release_count, :release_dir, :public_dir

        def initialize options={}
          config.options.each do |opt,val|
            config.send opt, options.fetch(opt,val)
          end

          raise ArgumentError, "a remote is required" unless config.remote
        end

        def run command
          config.ssh_session.run command
        end

        def done
          config.ssh_session.close_session
        end

        def create_remote_dir path
          unless path[0] == "/"
            raise ArgumentError, "path must be absolute"
          end

          Log.info "Setting up directory at '#{path}' on #{config.remote}"
          run "mkdir -p #{path}"
        end

        def rsync_to_remote local_path, remote_path
          local_path  = local_path.chomp("/")
          remote_path = remote_path.chomp("/")

          Log.info "Syncing files frome '#{local_path}' to '#{remote_path}' on #{config.remote}"

          time_before = Time.now
          resp = Shell.run_local "rsync #{rsync_options} " +
                                 "-e ssh #{local_path}/ " +
                                 "#{host_connection}:#{remote_path}/"
          time_after = Time.now
          total_time = (time_after - time_before).round(2)

          if resp.success?
            Log.info :success, "Files synced to remote on #{config.remote} in #{total_time}s"
          else
            Log.error "Error syncing files to remote on #{config.remote}",
                      resp.stderr
          end

          resp
        end

        private

          def host_connection
            config.user ? "#{config.user}@#{config.remote}" : config.remote
          end

          def rsync_options
            "-aqz --delete-after"
          end

      end

    end
  end
end