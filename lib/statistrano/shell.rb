module Statistrano
  module Shell

    class << self
      include HereOrThere

      def run command, &block
        stdout, stderr, status = Open3.capture3(command)

        if status.success?
          yield stdout if block_given?
          [ true, stdout, stderr ]
        else
          $stderr.puts "Problem running #{command}"
          $stderr.puts stderr
          false
        end
      rescue StandardError => e
        $stderr.puts "Problem running '#{command}'"
        $stderr.puts "Error: #{e}"
      end

      # get input from the command line
      # @return [String]
      def get_input message
        print message
        $stdin.gets.chomp
      end

    end

  end
end