module Statistrano
  module Git

    class << self

      # Check if working tree is clean
      # @return [Boolean] true if branch is clean
      def working_tree_clean?
        if /nothing to commit/.match(`git status 2> /dev/null`)
          return true
        else
          return false
        end
      end

      # Get current git branch based on exec directory
      # @return [String] the current checked out branch
      def current_branch
        `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
      end

      # Get current git commit based on exec directory
      # @return [String] the current commit level
      def current_commit
        `git rev-parse HEAD 2> /dev/null`.strip
      end

      # Check if branch is in sync with remote
      # @return [Boolean]
      def remote_up_to_date?
        `git push -n 2>&1` == "Everything up-to-date\n"
      end

    end

  end
end