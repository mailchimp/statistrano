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
        option :release_count,    5
        option :release_dir,      "releases"
        option :public_dir,       "current"

        option :remotes, []

        validate :release_dir, lambda { |d| !d.to_s.empty? && d != '/' },
                 "'release_dir' can't be an empty string or '/'"

        validate :public_dir, lambda { |d| !d.to_s.empty? && d != '/' },
                 "'public_dir' can't be an empty string or '/'"

        validate :release_count, lambda { |c| c.is_a?(Integer) && c > 0 },
                 "'release_count' must be an integer greater than 0"

        task :deploy,   :deploy,           "Deploy to all remotes"
        task :rollback, :rollback_release, "Rollback to the previous release"
        task :prune,    :prune_releases,   "Prune releases to release count"
        task :list,     :list_releases,    "List releases"

        def initialize name
          @name = name
        end

        def rollback_release
          remotes.each do |remote|
            releaser.rollback_release remote
          end
        end

        def prune_releases
          remotes.each do |remote|
            releaser.prune_releases remote
          end
        end

        def list_releases
          remotes.each do |remote|
            releases = releaser.list_releases(remote).map { |rel| rel[:release] }
            Log.info :"#{remote.config.hostname}", releases
          end
        end

        private

          def releaser
            Releaser::Revisions.new
          end

      end

    end
  end
end
