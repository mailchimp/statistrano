module Statistrano

  # Utility methods
  class Util

    # Fun monkey-related adjective-noun names
    # @return [String]
    def self.monkey_name
      nouns = ["baboon", "chimpanzee", "capuchin", "macaque", "colobus", "guenon", "howler", "langur", "mandrill", "mangabey", "marmoset", "rhesus", "tamarin", "uakari", "woolly", "anthropoid", "ape", "baboon", "chimpanzee", "gorilla", "lemur", "orangutan", "simian", "banana", "plantain"]
      adjectives = ["brown", "blue", "red", "yellow", "orange", "green", "silver", "black", "teal", "cyan", "purple", "magenta", "sandy", "tan"]
      "#{adjectives.sample}-#{nouns.sample}-#{rand(1..100)}"
    end
  end

end