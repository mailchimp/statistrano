module Statistrano
  module Shell

    class << self
      include HereOrThere

      # get input from the command line
      # @return [String]
      def get_input message
        print message
        $stdin.gets.chomp
      end

    end

  end
end
