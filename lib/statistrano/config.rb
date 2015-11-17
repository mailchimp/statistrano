require_relative 'config/configurable'
require_relative 'config/rake_task_with_context_creation'

module Statistrano
  class Config
    include RakeTaskWithContextCreation

    attr_reader :options,
                :tasks,
                :validators

    # initalize with the potential for seed options
    # this is required so that when config'd classes
    # are extended we can pass that configuration along
    def initialize options: nil, tasks: nil, validators: nil
      @options    = options.nil?    ? {} : options.clone
      @tasks      = tasks.nil?      ? {} : tasks.clone
      @validators = validators.nil? ? {} : validators.clone

      @options.each do |key,val|
        define_option_accessor key.to_sym
      end

      @validators.each do |key,val|
        define_validator key.to_sym
      end
    end

    private

      def define_validator name
        define_singleton_method(:"validator_for_#{name}") do |proc, message|
          @validators[name] = { validator: proc,
                                message: message }
        end

        define_singleton_method(:"validate_#{name}") do |arg|
          if @validators.has_key?(name) && !@validators[name][:validator].call(arg)
            raise ValidationError, (@validators[name][:message] || "configuration option for '#{name}' failed it's validation")
          end
        end
      end

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

      class ValidationError < StandardError
      end

  end
end
