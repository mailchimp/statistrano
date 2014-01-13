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

      options :remote_dir, :local_dir
      option  :targets, []

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

      def deploy
        invoke_build_task

        releaser = Releaser.new config.options
        targets.each do |t|
          releaser.create_release t
        end

        invoke_post_deploy_task
      end
    end

  end
end

require_relative 'multi_target/releaser'
require_relative 'multi_target/target'
require_relative 'multi_target/manifest'
