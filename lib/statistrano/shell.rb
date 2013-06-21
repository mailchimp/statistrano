require 'open3'

module Statistrano
  module Shell

    class << self

      def run command, &block
        stdout, stderr, status = Open3.capture3(command)
        STDERR.puts(stderr)

        if status.success?
          yield stdout if block_given?
          [ true, stdout ]
        else
          STDERR.puts "Problem running #{command}"
          false
        end
      rescue StandardError => e
        STDERR.puts "Problem running '#{command}'"
        STDERR.puts "Error: #{e}"
      end

    end

  end
end