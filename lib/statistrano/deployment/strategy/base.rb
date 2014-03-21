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

        attr_reader :name

        register_strategy :base

        options :remote_dir, :local_dir,
                :remote, :user, :password, :keys, :forward_agent,
                :build_task, :post_deploy_task,
                :check_git, :git_branch, :repo_url

        task :deploy, :deploy, "Deploy to remote"

        # create a new deployment instance
        # @param name [String]
        # @return [Void]
        def initialize name
          @name = name
          RakeTasks.register(self)
        end

        def run_action method_name
          prepare_for_action
          self.send(method_name)
          done_with_action
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

        private

          def remote
            return @_remote if @_remote

            options = config.options.dup
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

          # Check if things are safe to deploy
          # @return [Boolean]
          def safe_to_deploy?

            # if we don't want to check git
            # we're good to go
            if !config.check_git
              return true
            end

            # are there any uncommited changes?
            if !Asgit.working_tree_clean?
              Log.warn "You need to commit or stash your changes before deploying"
              return false
            end

            # make sure you're on the branch selected to check against
            if Asgit.current_branch != config.git_branch
              Log.warn "You shouldn't deploy from any branch but #{config.git_branch}"
              return false
            end

            # make sure you're up to date
            if !Asgit.remote_up_to_date?
              Log.warn "You need to update or push your changes before deploying"
              return false
            end

            # we passed all the checks
            return true
          end

      end

    end
  end
end