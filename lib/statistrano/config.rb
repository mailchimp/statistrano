require 'statistrano/config/configurable'

module Statistrano
  class Config

    attr_reader :options
    attr_reader :tasks

    # initalize with the potential for seed options
    # this is required so that when config'd classes
    # are extended we can pass that configuration along
    def initialize options=nil, tasks=nil
      @options =  options.nil?  ? {} : options.clone
      @tasks = tasks.nil? ? {} : tasks.clone

      @options.each do |key,val|
        name = key.to_sym
        define_option_accessor name
      end
    end

    private

      def define_option_accessor name
        define_singleton_method(name) do |*args|
          if args.length == 1
            @options[name] = args[0]
          elsif args.empty?
            @options[name]
          else
            raise ArgumentError, "wrong number of arguments (#{args.length} for 0..1)"
          end
        end
        define_singleton_method("#{name}=") { |arg| @options[name] = arg }
      end

  end
end