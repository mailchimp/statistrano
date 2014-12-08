module Statistrano
  module Deployment
    module Strategy

      # A Base Deployment Instance
      # it holds the common methods needed
      # to create a deployment
      class Base
        extend Deployment::Registerable
        extend Config::Configurable
        include InvokeTasks
        include CheckGit

        attr_reader :name

        register_strategy :base

        options :remote_dir, :local_dir,
                :hostname, :user, :password, :keys, :forward_agent,
                :build_task, :post_deploy_task,
                :check_git, :git_branch, :repo_url,
                :dir_permissions, :file_permissions, :rsync_flags,
                :log_file_path, :log_file_entry

        option  :remotes, []
        option  :dir_permissions, 755
        option  :file_permissions, 644
        option  :rsync_flags, '-aqz --delete-after'

        option  :verbose, false

        task :deploy,      :deploy,                  "Deploy to remote"
        task :build,       :invoke_build_task,       "Run build task"
        task :post_deploy, :invoke_post_deploy_task, "Run post deploy task"

        # create a new deployment instance
        # @param name [String]
        # @return [Void]
        def initialize name
          @name = name
        end

        # Standard deployment flow
        # @return [Void]
        def deploy
          unless safe_to_deploy?
            Log.error "exiting due to git check failing"
            abort()
          end

          build_data = invoke_build_task
          build_data = ensure_data_is_hash build_data

          unless safe_to_deploy?
            Log.error "exiting due to git check failing",
                      "your build task modified checked in files"
            abort()
          end

          remotes.each do |remote|
            persisted_releaser.create_release remote, build_data
          end

          post_deploy_data = invoke_post_deploy_task
          post_deploy_data = ensure_data_is_hash post_deploy_data

          if config.log_file_path
            log_entry = config.log_file_entry.call self, persisted_releaser,
                                                   build_data, post_deploy_data

            remotes.each do |remote|
              log_file(remote).append! log_entry
            end
          end

          flush_persisted_releaser!
        end

        def register_tasks
          RakeTasks.register self
        end

        def remotes
          return @_remotes if @_remotes

          @_remotes = config.options[:remotes].map do |remote_options|
            Remote.new Config.new( config.options.dup.merge(remote_options) )
          end
          @_remotes.push Remote.new(config) if @_remotes.empty?

          return @_remotes
        end

        def log_file remote=remotes.first
          Deployment::LogFile.new config.log_file_path, remote
        end

        def persisted_releaser
          @_persisted_releaser ||= releaser
        end

        def flush_persisted_releaser!
          @_persisted_releaser = nil
        end

        private

          def resolve_log_file_path
            if config.log_file_path.start_with? '/'
              config.log_file_path
            else
              File.join( config.remote_dir, config.log_file_path )
            end
          end

          def ensure_data_is_hash data
            if data.respond_to? :to_hash
              data = data.to_hash
            else
              data = {}
            end
          end

          def releaser
            Releaser::Single.new
          end

      end

    end
  end
end
