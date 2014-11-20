require_relative 'config/configurable'

module Statistrano
  class Config

    attr_reader :options
    attr_reader :tasks

    # initalize with the potential for seed options
    # this is required so that when config'd classes
    # are extended we can pass that configuration along
    def initialize options=nil, tasks=nil
      @options = options.nil? ? {} : options.clone
      @tasks   = tasks.nil?   ? {} : tasks.clone

      @options.each do |key,val|
        define_option_accessor key.to_sym
      end
    end

    private

      def define_option_accessor name
        define_singleton_method(name) do |*args, &block|
          if block
            if args.first == :call
              @options[name] = { call: block }
            else
              @options[name] = block
            end
            return
          end

          if args.length == 1
            @options[name] = args[0]
          elsif args.empty?
            if @options[name].respond_to? :fetch
              @options[name].fetch( :call, -> { @options[name] } ).call
            else
              @options[name]
            end
          else
            raise ArgumentError, "wrong number of arguments (#{args.length} for 0..1)"
          end
        end
        define_singleton_method("#{name}=") { |arg| @options[name] = arg }
      end

  end
end
