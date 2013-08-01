module Statistrano

  # opens and runs commands through ssh sessions
  # optionaly closes them as well
  class SSH

    def initialize config
      @config = config
      @session = start_session
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
    # @return [String] stdout from remote command
    def run_command command # :yields: :channel, :stream, :data
      begin
        @session.exec! command do |channel, stream, data|
          if stream == :stderr
            LOG.error "Error executing the command:\n\t\"#{command}\"" +
                      "\n" +
                      "\n\tRemote Error:\n\t#{data}"
            exit
          else
            yield(channel, stream, data) if block_given?
            return data
          end
        end
      rescue Net::SSH::AuthenticationFailed
        close_session
        LOG.error "Authentication failed when connecting to '#{@config.remote}'"
      rescue Exception => e
        close_session
        LOG.error "Error when attempting to connect to '#{@config.remote}'" +
                  "\n\t  msg  #{e.class}: #{e}" +
                  "\n    backtrace\n#{e.backtrace.join("\n")}"
      end
    end

    # open a Net::SSH session
    # @returns [Net::SSH::Session]
    def start_session
      LOG.msg "Opening SSH Session: #{self.object_id}"
      session = Net::SSH.start @config.remote, @config.user, ssh_options
      return session
    end

    def close_session
      unless @session.closed?
        LOG.msg "Closing SSH Session"
        @session.close
      end
    end

  end
end