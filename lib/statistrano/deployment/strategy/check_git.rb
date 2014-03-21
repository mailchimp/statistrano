module Statistrano
  module Deployment
    module Strategy

      module CheckGit

        # Check if things are safe to deploy
        # @return [Boolean]
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
end