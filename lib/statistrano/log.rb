# encoding: UTF-8
require 'colorize'

module Statistrano

  # Error, Warning and Message Logging
  class Log

    # Log a regular message
    # @param [String] text
    def msg text, status="success", color=:green
      shell_say status, text, color
    end

    # Log a regular message
    # @param [String] text
    def warn text, status="warning", color=:yellow
      shell_say status, text, color
    end

    # Log a regular message
    # @param [String] text
    def error text, status="error", color=:red
      shell_say status, text, color
    end

    private

      # Put output into stdout
      #
      # @param message [String]
      # @param status [String]
      # @param color [Symbol]
      def shell_say message, status, color
        $stdout.puts "#{status.colorize(color)}  #{message}"
        $stdout.flush
      end

  end

  # Define the log constant
  LOG = Log.new()

end