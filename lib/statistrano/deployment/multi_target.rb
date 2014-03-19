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

        targets.each do |t|
          releaser.create_release t, build_data
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
          Log.info :"#{t.config.remote}", releases
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
            Log.info :post_deploy, "Running the post deploy task"
            call_or_invoke_task config.post_deploy_task
          end
        end

        # Run the build_task supplied
        # return [Void]
        def invoke_build_task
          Log.info :build, "Running the build task"
          call_or_invoke_task config.build_task
        end

        def call_or_invoke_task task
          if task.respond_to? :call
            task.call
          else
            Rake::Task[task].invoke
          end
        rescue Exception => e
          Log.error "exiting due to error in build task",
                    "#{e.class}: #{e}"
          abort()
        end

        def safe_to_deploy?
          # if we don't want to check git
          # we're good to go
          if !config.check_git
            return true
          end

          # are there any uncommited changes?
          if !Asgit.working_tree_clean?
            Log.warn "You need to commit or stash your changes before deploying"
            return false
          end

          # make sure you're on the branch selected to check against
          if Asgit.current_branch != config.git_branch
            Log.warn "You shouldn't deploy from any branch but #{config.git_branch}"
            return false
          end

          # make sure you're up to date
          if !Asgit.remote_up_to_date?
            Log.warn "You need to update or push your changes before deploying"
            return false
          end

          # we passed all the checks
          return true
        end

    end

  end
end

require_relative 'multi_target/releaser'
require_relative 'multi_target/target'
require_relative 'multi_target/manifest'
