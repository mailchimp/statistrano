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
        end

        def run command
          config.ssh_session.run command
        end

        def done
          config.ssh_session.close_session
        end

      end

    end
  end
end