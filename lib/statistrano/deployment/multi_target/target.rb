module Statistrano
  module Deployment
    class MultiTarget

      # a target is a databag of config specific for an
      # individual target for a MultiTarget deployment
      # including it's own ssh connection to it's remote
      #
      class Target
        extend ::Statistrano::Config::Configurable

        options :remote_dir, :local_dir,
                :remote, :user, :password, :keys, :forward_agent

        option :release_count, 5
        option :release_dir, "releases"
        option :public_dir,  "current"

        def initialize options={}
          config.options.each do |opt,val|
            config.send opt, options.fetch(opt,val)
          end
        end

      end

    end
  end
end