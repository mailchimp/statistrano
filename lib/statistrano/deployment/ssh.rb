module Statistrano
  module Deployment

    class SSH

      def initialize config
        @config = config
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
      def run_command command # :yields: :channel, :stream, :data
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
          LOG.error "Authentication failed when connecting to '#{@config.remote}'"
        rescue Exception
          LOG.error "Error when attempting to connect to '#{@config.remote}'"
        end
      end

    end

  end
end