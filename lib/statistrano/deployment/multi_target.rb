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
    class MultiTarget
      extend ::Statistrano::Deployment::Registerable
      extend ::Statistrano::Config::Configurable

      register_type :multi_target

      options :remote_dir, :local_dir,
              :remote, :user, :password, :keys, :forward_agent,
              :build_task, :post_deploy_task,
              :check_git, :git_branch, :repo_url

      option :release_count, 5
      option :release_dir, "releases"
      option :public_dir,  "current"

      option  :targets, []

      def initialize name
        @name = name
      end

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

        targets.each do |t|
          releaser.create_release t
        end

        invoke_post_deploy_task
      end

      def rollback_release
        targets.each do |t|
          releaser.rollback_release t
        end
      end

      def prune_releases
        targets.each do |t|
          releaser.prune_releases t
        end
      end

      def list_releases
        targets.each do |t,out|
          releases = releaser.list_releases(t).map { |rel| rel[:release] }
          LOG.msg releases, t.config.remote
        end
      end

      private

        def releaser
          Releaser.new config.options
        end

        # Run the post_deploy_task
        # return [Void]
        def invoke_post_deploy_task
          if config.post_deploy_task
            LOG.msg "Running the post deploy task", nil
            Rake::Task[ config.post_deploy_task ].invoke
          end
        end

        # Run the build_task supplied
        # return [Void]
        def invoke_build_task
          Rake::Task[config.build_task].invoke
        rescue Exception => e
          LOG.error "exiting due to error in build task" +
            "\n\t  msg  #{e.class}: #{e}"
        end

    end

  end
end

require_relative 'multi_target/releaser'
require_relative 'multi_target/target'
require_relative 'multi_target/manifest'
