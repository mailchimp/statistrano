module Statistrano
  module Deployment
    module Strategy

      # A Base Deployment Instance
      # it holds the common methods needed
      # to create a deployment
      class Base
        extend ::Statistrano::Deployment::Registerable
        extend ::Statistrano::Config::Configurable

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

          # Run the post_deploy_task
          # return [Void]
          def invoke_post_deploy_task
            if config.post_deploy_task
              Log.info :post_deploy, "Running the post deploy task"
              call_or_invoke_task config.post_deploy_task
            end
          end

          # Run the build_task supplied
          # return [Void]
          def invoke_build_task
            Log.info :build, "Running the build task"
            call_or_invoke_task config.build_task
          end

          def call_or_invoke_task task
            if task.respond_to? :call
              task.call
            else
              Rake::Task[task].invoke
            end
          rescue Exception => e
            Log.error "exiting due to error in build task",
                      "#{e.class}: #{e}"
            abort()
          end

          def prepare_for_action
            ENV["DEPLOYMENT_ENVIRONMENT"] = @name
          end

          def done_with_action
            remote.done
          end

          # # get paths, etc setup on remote
          # def setup
          #   remote.run "mkdir -p #{config.remote_dir}"
          # end

          # # send code to remote server
          # # @return [Void]
          # def create_release
          #   setup_release_path config.remote_dir
          #   rsync_to_remote config.remote_dir

          #   Log.info "Created release at #{config.remote_dir}"
          # end

          # # create the release dir on the remote
          # # @param release_path [String] path of release on remote
          # # @return [Void]
          # def setup_release_path release_path
          #   Log.info "Setting up the remote"
          #   remote.run "mkdir -p #{release_path}"
          # end

          # # rsync files from local_dir to the remote
          # # @param remote_path [String] path to sync to on remote
          # # @return [Void]
          # def rsync_to_remote remote_path
          #   Log.info "Syncing files to remote"

          #   time = Benchmark.realtime do
          #     if Shell.run_local("rsync #{rsync_options} -e ssh #{local_path}/ #{host_connection}:#{remote_path}/").success?
          #       Log.info :success, "Files synced to remote"
          #     else
          #       Log.error "Error syncing files to remote"
          #     end
          #   end

          #   Log.info "Synced in #{time} seconds"
          # end

          # def rsync_options
          #   "-aqz --delete-after"
          # end

          # # gives the host connection for ssh based on config settings
          # # @return [String]
          # def host_connection
          #   config.user ? "#{config.user}@#{config.remote}" : config.remote
          # end

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

          # # Remove the local_directory
          # # @return [Void]
          # def clean_up
          #   Log.info "Cleaning up"
          #   FileUtils.rm_r local_path
          # end

          # # Get the path to the local directory
          # # @return [String] full local path
          # def local_path
          #   File.join( Dir.pwd, config.local_dir )
          # end

          # # Run the post_deploy_task
          # # return [Void]
          # def invoke_post_deploy_task
          #   if config.post_deploy_task
          #     Log.info "Running the post deploy task"
          #     Rake::Task[ config.post_deploy_task ].invoke
          #   end
          # end

          # # Run the build_task supplied
          # # return [Void]
          # def invoke_build_task
          #   Rake::Task[config.build_task].invoke
          # rescue Exception => e
          #   Log.error "exiting due to error in build task",
          #             "#{e.class}: #{e}"
          #   abort()
          # end

      end

    end
  end
end