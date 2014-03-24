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
                :check_git, :git_branch, :repo_url

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
          releaser.create_release remote
          invoke_post_deploy_task
        end

        def register_tasks
          RakeTasks.register self
        end

        private

          def remote
            return @_remote if @_remote

            options  = config.options.dup
            @_remote = Remote.new options
          end

          def releaser
            Releaser::Single.new config.options
          end

          def prepare_for_action
            ENV["DEPLOYMENT_ENVIRONMENT"] = @name
          end

          def done_with_action
            remote.done
          end

      end

    end
  end
end