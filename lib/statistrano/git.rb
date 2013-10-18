module Statistrano
  module Git

    class << self

      # Check if working tree is clean
      # @return [Boolean] true if branch is clean
      def working_tree_clean?
        Shell.run_local('git status').stdout.include? 'nothing to commit'
      end

      # Get current git branch based on exec directory
      # @return [String] the current checked out branch
      def current_branch
        Shell.run_local( "git symbolic-ref HEAD" ).stdout
          .strip.gsub(/^refs\/heads\//, '')
      end

      # Get current git commit based on exec directory
      # @return [String] the current commit level
      def current_commit
        Shell.run_local( "git rev-parse HEAD" ).stdout.strip
      end

      # Check if branch is in sync with remote
      # @return [Boolean]
      def remote_up_to_date?
        resp = Shell.run_local "git push --dry-run"
        return resp.status && resp.stderr.include?( "Everything up-to-date" )
      end

    end

  end
end