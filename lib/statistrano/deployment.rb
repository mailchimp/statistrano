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
        attr_accessor :post_deploy_task
      end

      # create a new deployment instance
      # @param name [String]
      # @return [Void]
      def initialize name
        @name = name
        @config = Config.new
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

        LOG.msg "Deployment Complete"
      end

      private

        # send code to remote server
        # @return [Void]
        def create_release
          setup_release_path @config.remote_dir
          rsync_to_remote @config.remote_dir

          # TODO: add_manifest

          LOG.msg "Created release at #{public_dir}"
        end

        # create the release dir on the remote
        # @param release_path [String] path of release on remote
        # @return [Void]
        def setup_release_path release_path
          LOG.msg "Setting up the remote"
          run_ssh_command "mkdir -p #{release_path}"
        end

        # rsync files from local_dir to the remote
        # @param remote_path [String] path to sync to on remote
        # @return [Void]
        def rsync_to_remote remote_path
          host_connection = @config.user ? "#{@config.user}@#{@config.remote}" : @config.remote
          LOG.msg "Syncing files to remote"
          if system "rsync -avqz -e ssh #{local_path}/ #{host_connection}:#{current_release}/"
            LOG.msg "Files synced to remote"
          else
            LOG.error "Error syncing files to remote"
            abort
          end
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

        # Filter options for ssh commands
        # @return [Hash]
        def ssh_options
          options = {}
          [:user, :password, :keys, :forward_agent].each do |key|
            value = @config.instance_variable_get("@#{key}")
            options[key] = value if value
          end
          return options
        end

        # Run ssh sync command and handle exceptions
        # @param [String] command the shell command to run
        # @return [Void]
        def run_ssh_command command # :yields: :channel, :stream, :data
          begin
            Net::SSH.start @config.remote, @config.user, ssh_options do |ssh|
              ssh.exec command do |channel, stream, data|
                if stream == :stderr
                  LOG.error "Error executing the command:\n\t\"#{command}\"" +
                            "\n" +
                            "\n\tRemote Error:\n\t#{data}"
                  exit
                else
                  yield(channel, stream, data) if block_given?
                end
              end
            end
          rescue Net::SSH::AuthenticationFailed
            LOG.error "Authentication failed when connecting to '#{@remote}'"
          end
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