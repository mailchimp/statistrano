module Statistrano
  module Deployment

    # deployment type for running a releases deployment
    # accross multiple remotes
    #
    # @example:
    #
    #   define_deployment "multi", :multi_target do
    #     build_task 'deploy:build'
    #     local_dir  'build'
    #     remote_dir '/var/www/proj'
    #
    #     check_git  true
    #     git_branch 'master'
    #
    #     targets [
    #       { remote: 'web01' },
    #       { remote: 'web02' }
    #     ]
    #
    #     # each target gets merged with the global
    #     # configs and deployed to individually
    #     #
    #   end
    #
    class MultiTarget < Base
      register_type :multi_target

      option :release_count, 5
      option :release_dir, "releases"
      option :public_dir,  "current"

      option :targets, []

      def targets
        return @_targets if @_targets

        options = config.options.dup
        targets = options.delete(:targets).map do |t|
                    options.merge(t)
                  end

        @_targets = targets.map do |t|
                      Target.new(t)
                    end
      end

      class Target
        extend ::Statistrano::Config::Configurable

        options :remote_dir, :local_dir,
                :remote, :user, :password, :keys, :forward_agent

        option :release_count, 5
        option :release_dir, "releases"
        option :public_dir,  "current"
      end
    end

  end
end