module Statistrano

  # Utility methods
  class Util
    # Check if working tree is clean
    # @return [Boolean] true if branch is clean
    def self.working_tree_clean?
      if /nothing to commit/.match(`git status 2> /dev/null`)
        return true
      else
        return false
      end
    end

    # Get current git branch based on exec directory
    # @return [String] the current checked out branch
    def self.current_git_branch
      `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
    end

    # Get current git commit based on exec directory
    # @return [String] the current commit level
    def self.current_git_commit
      `git rev-parse HEAD 2> /dev/null`.strip
    end

    # Check if branch is in sync with remote
    # @return [Boolean]
    def self.remote_up_to_date?
      `git push -n 2>&1` == "Everything up-to-date\n"
    end

    # Fun monkey-related adjective-noun names
    # @return [String]
    def self.monkey_name
      nouns = ["baboon", "chimpanzee", "capuchin", "macaque", "colobus", "guenon", "howler", "langur", "mandrill", "mangabey", "marmoset", "rhesus", "tamarin", "uakari", "woolly", "anthropoid", "ape", "baboon", "chimpanzee", "gorilla", "lemur", "orangutan", "simian", "banana", "plantain"]
      adjectives = ["brown", "blue", "red", "yellow", "orange", "green", "silver", "black", "teal", "cyan", "purple", "magenta", "sandy", "tan"]
      "#{adjectives.sample}-#{nouns.sample}-#{rand(1..100)}"
    end
  end

end