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
        attr_accessor :build_task
        attr_accessor :check_git
        attr_accessor :post_deploy_task
      end

      # create a new deployment instance
      # @param name [String]
      # @return [Void]
      def initialize name
        @name = name
        @config = Config.new
      end

      private

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
            Net::SSH.start @remote, @user, ssh_options do |ssh|
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

    end


  end
end