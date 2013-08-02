module Statistrano
  module Deployment

    # A Base Deployment Instance
    # it holds the common methods needed
    # to create a deployment
    class Base

      attr_reader :name
      attr_reader :config

      # Config holds configuration for this
      # particular deployment
      class Config
        extend ConfigAttribute
        config_attribute :remote_dir
        config_attribute :local_dir

        config_attribute :remote
        config_attribute :user, :password, :keys, :forward_agent

        config_attribute :build_task
        config_attribute :check_git
        config_attribute :git_branch
        config_attribute :repo_url
        config_attribute :post_deploy_task

        def tasks
          {
            :deploy => { method: :deploy, desc: "Deploy to remote" }
          }
        end

        def configure &block
          if block.arity == 1
            yield self
          else
            instance_eval &block
          end
        end
      end

      # create a new deployment instance
      # @param name [String]
      # @return [Void]
      def initialize name
        @name = name
        config
        RakeTasks.register(self)
      end

      # initializes a config or returns
      # the existing one
      # @return [Config]
      def config
        @_config ||= Config.new
      end

      # hook to manipulate the configuration
      # @yield [config] yields the configuration
      # @return [Void]
      def configure &block
        config.configure &block
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
          LOG.error "exiting due to git check failing"
        end

        LOG.msg "starting deployment to #{name}", "deploying"

        invoke_build_task
        setup
        create_release
        clean_up
        invoke_post_deploy_task

        LOG.success "Deployment Complete"
      end

      private

        def prepare_for_action
          ENV["DEPLOYMENT_ENVIRONMENT"] = @name
          @ssh = ::Statistrano::SSH.new( config )
        end

        def done_with_action
          @ssh.close_session
        end

        # get paths, etc setup on remote
        def setup
          @ssh.run_command "mkdir -p #{config.remote_dir}"
        end

        # send code to remote server
        # @return [Void]
        def create_release
          setup_release_path config.remote_dir
          rsync_to_remote config.remote_dir

          LOG.msg "Created release at #{config.remote_dir}"
        end

        # create the release dir on the remote
        # @param release_path [String] path of release on remote
        # @return [Void]
        def setup_release_path release_path
          LOG.msg "Setting up the remote"
          @ssh.run_command "mkdir -p #{release_path}"
        end

        # rsync files from local_dir to the remote
        # @param remote_path [String] path to sync to on remote
        # @return [Void]
        def rsync_to_remote remote_path
          LOG.msg "Syncing files to remote"

          time = Benchmark.realtime do
            if Shell.run "rsync #{rsync_options} -e ssh #{local_path}/ #{host_connection}:#{remote_path}/"
              LOG.success "Files synced to remote"
            else
              LOG.error "Error syncing files to remote"
            end
          end

          LOG.msg "Synced in #{time} seconds"
        end

        def rsync_options
          "-aqz --delete-after"
        end

        # gives the host connection for ssh based on config settings
        # @return [String]
        def host_connection
          config.user ? "#{config.user}@#{config.remote}" : config.remote
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
          if !Git.working_tree_clean?
            LOG.warn "You need to commit or stash your changes before deploying"
            return false
          end

          # make sure you're on the branch selected to check against
          if Git.current_branch != config.git_branch
            LOG.warn "You shouldn't deploy from any branch but #{config.git_branch}"
            return false
          end

          # make sure you're up to date
          if !Git.remote_up_to_date?
            LOG.warn "You need to update or push your changes before deploying"
            return false
          end

          # we passed all the checks
          return true
        end

        # Remove the local_directory
        # @return [Void]
        def clean_up
          LOG.msg "Cleaning up", nil
          FileUtils.rm_r local_path
        end

        # Get the path to the local directory
        # @return [String] full local path
        def local_path
          File.join( Dir.pwd, config.local_dir )
        end

        # Run the post_deploy_task
        # return [Void]
        def invoke_post_deploy_task
          if config.post_deploy_task
            LOG.msg "Running the post deploy task", nil
            Rake::Task[ config.post_deploy_task ].invoke
          end
        end

        # Run the build_task supplied
        # return [Void]
        def invoke_build_task
          Rake::Task[config.build_task].invoke
        rescue Exception => e
          LOG.error "exiting due to error in build task" +
            "\n\t  msg  #{e.class}: #{e}"
        end

    end


  end
end