require 'statistrano/config/configurable'

module Statistrano
  class Config

    attr_reader :data
    attr_reader :tasks

    # initalize with the potential for seed data
    # this is required so that when config'd classes
    # are extended we can pass that configuration along
    def initialize data=nil, tasks=nil
      @data =  data.nil?  ? {} : data.clone
      @tasks = tasks.nil? ? {} : tasks.clone
    end

    def option key, value
      data[key] = value
    end

    # set configuration with a block
    # runs method_missing to define config
    # attributes and their defaults
    #
    def set_with_block &block
      capture = CaptureConfigurationBlock.new
      capture.instance_eval &block

      data.merge!  capture.config
      tasks.merge! capture.tasks
    end

    # attempt to pull an undefined method out
    # of the data pile, or alternatively set
    # the value if the key has been defined
    #
    def method_missing method, *args, &block
      if !args.empty?
        key = method.to_s.gsub( /=$/, '' ).to_sym
        if data.has_key? key
          data[key] = args[0]
        else
          super
        end
      else
        data.fetch(method) { super }
      end
    end

    class CaptureConfigurationBlock

      def config
        @_config ||= {}
      end

      def tasks
        @_tasks ||= {}
      end

      def task name, method, description
        tasks[name] = { method: method, desc: description }
      end

      # capture methods as keys and their
      # arguments as the value
      #
      def method_missing method, *args, &block
        if !args.empty?
          config[method] = args[0]
        else
          super
        end
      end

    end

  end
end