module Statistrano
  module Deployment
    module Strategy

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
      class MultiTarget
        extend Deployment::Registerable
        extend Config::Configurable
        include InvokeTasks
        include CheckGit

        register_strategy :multi_target

        options :remote_dir, :local_dir,
                :hostname, :user, :password, :keys, :forward_agent,
                :build_task, :post_deploy_task,
                :check_git, :git_branch, :repo_url

        option :release_count, 5
        option :release_dir, "releases"
        option :public_dir,  "current"

        option :remotes, []

        def initialize name
          @name = name
        end

        def remotes
          return @_remotes if @_remotes

          options = config.options.dup
          remotes = options.delete(:remotes).map do |t|
                      options.merge(t)
                    end

          @_remotes = remotes.map do |t|
                        Remote.new(t)
                      end
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
            ::Statistrano::Deployment::Releaser::Revisions.new config.options
          end

      end

    end
  end
end

require_relative 'multi_target/manifest'
