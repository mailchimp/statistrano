module Statistrano
  module Deployment
    class MultiTarget

      # a target is a databag of config specific for an
      # individual target for a MultiTarget deployment
      # including it's own ssh connection to it's remote
      #
      class Target
        extend ::Statistrano::Config::Configurable
        options :remote, :user, :password, :keys, :forward_agent

        def initialize options={}
          config.options.each do |opt,val|
            config.send opt, options.fetch(opt,val)
          end

          raise ArgumentError, "a remote is required" unless config.remote
        end

        def run command
          config.ssh_session.run command
        end

        def done
          config.ssh_session.close_session
        end

        def create_remote_dir path
          unless path[0] == "/"
            raise ArgumentError, "path must be absolute"
          end

          LOG.msg "Setting up directory at '#{path}' on #{config.remote}"
          run "mkdir -p #{path}"
        end

      end

    end
  end
end