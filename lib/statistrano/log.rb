# encoding: UTF-8
require 'colorize'

module Statistrano

  # Error, Warning and Message Logging
  class Log

    # Log a regular message
    # @param [String] text
    def msg text, status=nil, color=:black
      status ||= ''
      shell_say text, status, color
    end

    # Log a success message
    def success text, status="success", color=:green
      shell_say text, status, color
    end

    # Log a regular message
    # @param [String] text
    def warn text, status="warning", color=:yellow
      shell_say text, status, color
    end

    # Log a regular message
    # @param [String] text
    def error text, status="error", color=:red
      shell_say text, status, color
      abort()
    end

    private

      # Put output into stdout
      #
      # @param message [String]
      # @param status [String]
      # @param color [Symbol]
      def shell_say message, status, color
        $stdout.puts "#{standardize(status, color)}  #{message}"
        $stdout.flush
      end

      # Standardize a width of output
      #
      # @param input [String]
      # @param color [Symbol]
      # @param width [Integer]
      # @return [String]
      def standardize input, color=:black, width=10
        output = "-> ".colorize(:black)
        len = input.length
        add = width - len
        add.times do
          output << " "
        end
        output << input.colorize(color)
      end

  end

  # Define the log constant
  LOG = Log.new()

end