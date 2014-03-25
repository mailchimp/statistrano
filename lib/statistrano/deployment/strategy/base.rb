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
                :dir_permissions, :file_permissions, :rsync_flags

        option  :remotes, []

        task :deploy, :deploy, "Deploy to remote"

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

          invoke_build_task

          remotes.each do |r|
            releaser.create_release r
          end

          invoke_post_deploy_task
        end

        def register_tasks
          RakeTasks.register self
        end

        def remotes
          return @_remotes if @_remotes

          options = config.options.dup
          remotes = options.delete(:remotes).map do |t|
                      options.merge(t)
                    end
          remotes.push options if remotes.empty?

          @_remotes = remotes.map do |t|
                        Remote.new(t)
                      end
        end

        private

          def releaser
            Releaser::Single.new config.options
          end

      end

    end
  end
end