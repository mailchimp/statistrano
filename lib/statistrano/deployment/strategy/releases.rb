module Statistrano
  module Deployment
    module Strategy

      # deployment type for running a releases deployment
      # accross multiple remotes
      #
      # @example:
      #
      #   define_deployment "multi", :releases do
      #     build_task 'deploy:build'
      #     local_dir  'build'
      #     remote_dir '/var/www/proj'
      #
      #     check_git  true
      #     git_branch 'master'
      #
      #     remotes [
      #       { hostname: 'web01' },
      #       { hostname: 'web02' }
      #     ]
      #
      #     # each remote gets merged with the global
      #     # configs and deployed to individually
      #     #
      #   end
      #
      class Releases < Base
        register_strategy :releases

        option :pre_symlink_task, nil
        option :release_count, 5
        option :release_dir, "releases"
        option :public_dir,  "current"

        option :remotes, []

        task :deploy,   :deploy,           "Deploy to all remotes"
        task :rollback, :rollback_release, "Rollback to the previous release"
        task :prune,    :prune_releases,   "Prune releases to release count"
        task :list,     :list_releases,    "List releases"

        def initialize name
          @name = name
        end

        def deploy
          unless safe_to_deploy?
            Log.error "exiting due to git check failing"
            abort()
          end

          build_data = invoke_build_task
          if build_data.respond_to? :to_hash
            build_data = build_data.to_hash
          else
            build_data = {}
          end

          remotes.each do |t|
            releaser.create_release t, build_data
          end

          invoke_post_deploy_task
        end

        def rollback_release
          remotes.each do |t|
            releaser.rollback_release t
          end
        end

        def prune_releases
          remotes.each do |t|
            releaser.prune_releases t
          end
        end

        def list_releases
          remotes.each do |t,out|
            releases = releaser.list_releases(t).map { |rel| rel[:release] }
            Log.info :"#{t.config.hostname}", releases
          end
        end

        private

          def releaser
            Releaser::Revisions.new config.options
          end

      end

    end
  end
end
