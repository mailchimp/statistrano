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
        attr_accessor :remote_dir
        attr_accessor :local_dir

        attr_accessor :remote
        attr_accessor :user, :password, :keys, :forward_agent

        attr_accessor :build_task
        attr_accessor :check_git
        attr_accessor :git_branch
        attr_accessor :repo_url
        attr_accessor :post_deploy_task

        def tasks
          {
            :deploy => { method: :deploy, desc: "Deploy to remote" }
          }
        end
      end

      # create a new deployment instance
      # @param name [String]
      # @return [Void]
      def initialize name
        @name = name
        @config = Config.new
        RakeTasks.register(self)
      end

      def prepare_for_action
        @ssh = ::Statistrano::SSH.new( @config )
        setup
      end

      # Standard deployment flow
      # @return [Void]
      def deploy

        unless safe_to_deploy?
          LOG.warn "exiting due to git check failing"
          abort
        end

        LOG.msg "starting deployment to #{name}", "deploying"

        invoke_build_task
        create_release
        clean_up
        invoke_post_deploy_task

        LOG.success "Deployment Complete"
      end

      private

        # get paths, etc setup on remote
        def setup
          @ssh.run_command "mkdir -p #{@config.remote_dir}"
        end

        # send code to remote server
        # @return [Void]
        def create_release
          setup_release_path @config.remote_dir
          rsync_to_remote @config.remote_dir

          LOG.msg "Created release at #{@config.remote_dir}"
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
          if system "rsync #{rsync_options} -e ssh #{local_path}/ #{host_connection}:#{remote_path}/"
            LOG.success "Files synced to remote"
          else
            LOG.error "Error syncing files to remote"
            abort
          end
        end

        def rsync_options
          "-aqz --delete-after"
        end

        # gives the host connection for ssh based on config settings
        # @return [String]
        def host_connection
          @config.user ? "#{@config.user}@#{@config.remote}" : @config.remote
        end

        # Check if things are safe to deploy
        # @return [Boolean]
        def safe_to_deploy?

          # if we don't want to check git
          # we're good to go
          if !@config.check_git
            return true
          end

          # are there any uncommited changes?
          if !Git.working_tree_clean?
            LOG.error "You need to commit or stash your changes before deploying"
            return false
          end

          # make sure you're on the branch selected to check against
          if Git.current_branch != @config.git_branch
            LOG.error "You shouldn't deploy from any branch but #{@config.git_branch}"
            return false
          end

          # make sure you're up to date
          if !Git.remote_up_to_date?
            LOG.error "You need to update or push your changes before deploying"
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
          File.join( Dir.pwd, @config.local_dir )
        end

        # Run the post_deploy_task
        # return [Void]
        def invoke_post_deploy_task
          if @config.post_deploy_task
            LOG.msg "Running the post deploy task", nil
            Rake::Task[ @config.post_deploy_task ].invoke
          end
        end

        # Run the build_task supplied
        # return [Void]
        def invoke_build_task
          Rake::Task[@config.build_task].invoke
        end

    end


  end
end