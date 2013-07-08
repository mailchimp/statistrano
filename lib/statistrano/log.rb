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
        $stdout.puts "#{StandardizeInput.new(status, color).output}  #{message}"
        $stdout.flush
      end

      # Standardize a width of output
      class StandardizeInput

        def initialize input, color=:black
          @input = input
          @color = color
          @width = 11
        end

        def output
          anchor + padding + @input.colorize(@color)
        end

        private

          def anchor
            "-> ".colorize(:black)
          end

          def padding
            Array.new( @width - @input.length ).join(" ")
          end
      end

  end

  # Define the log constant
  LOG = Log.new()

end