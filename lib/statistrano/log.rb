# encoding: UTF-8
require_relative 'log/default_logger'

module Statistrano

  # interface should match the ruby logger
  # so we will implement:
  #
  # => fatal
  # => error
  # => warn
  # => info
  # => debug
  #
  # note that DefaultLogger does accept multiline logs
  # as *args so you will need a wrapper for some logging libraries

  class Log
    extend SingleForwardable
    def_delegators :logger_instance, :fatal, :error, :warn, :info, :debug

    class << self
      def set_logger logger
        @_logger = logger
      end

      def logger_instance
        @_logger ||= DefaultLogger.new
      end
    end
  end

end