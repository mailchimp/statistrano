module Statistrano
  module Git

    class << self

      # Check if working tree is clean
      # @return [Boolean] true if branch is clean
      def working_tree_clean?
        Shell.run "git status" do |output|
          return output.include? "nothing to commit"
        end
      end

      # Get current git branch based on exec directory
      # @return [String] the current checked out branch
      def current_branch
        Shell.run "git symbolic-ref HEAD" do |output|
          return output.strip.gsub(/^refs\/heads\//, '')
        end
      end

      # Get current git commit based on exec directory
      # @return [String] the current commit level
      def current_commit
        Shell.run "git rev-parse HEAD" do |output|
          return output.strip
        end
      end

      # Check if branch is in sync with remote
      # @return [Boolean]
      def remote_up_to_date?
        status, stdout, stderr = Shell.run "git push --dry-run"
        return status && stderr.include?( "Everything up-to-date" )
      end

    end

  end
end