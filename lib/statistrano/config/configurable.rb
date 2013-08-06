module Statistrano
  class Config
    module Configurable

      def configuration
        @_configuration ||= Config.new()
      end

      def configure &block
        if block.arity == 1
          yield configuration
        else
          configuration.set_with_block &block
        end
      end

      def self.extended extending_obj
        extending_obj.send :define_method,
          :config, lambda { @_config ||= Config.new( self.class.configuration.data, self.class.configuration.tasks ) }
      end

      def inherited subclass
        subclass.superclass.class_eval do
          subclass.configuration.data.merge! subclass.superclass.configuration.data
          subclass.configuration.tasks.merge! subclass.superclass.configuration.tasks
        end
      end

    end
  end
end