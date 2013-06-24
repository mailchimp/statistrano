require 'open3'

module Statistrano
  module Shell

    class << self

      def run command, &block
        stdout, stderr, status = Open3.capture3(command)
        $stderr.puts(stderr)

        if status.success?
          yield stdout if block_given?
          [ true, stdout ]
        else
          $stderr.puts "Problem running #{command}"
          false
        end
      rescue StandardError => e
        $stderr.puts "Problem running '#{command}'"
        $stderr.puts "Error: #{e}"
      end

    end

  end
end