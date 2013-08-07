module Statistrano
  class Config
    module Configurable

      def configuration
        @_configuration ||= Config.new()
      end

      def option key, value=nil
        configuration.data[key] = value
      end

      def options *args
        args.each { |a| option(a) }
      end

      def task name, method, description
        configuration.tasks[name] = {
          method: method,
          desc: description
        }
      end

      # add a config method to objects that
      # extend Configurable
      #
      def self.extended extending_obj
        extending_obj.send :define_method,
          :config, lambda { @_config ||= Config.new( self.class.configuration.data, self.class.configuration.tasks ) }
      end

      # make sure that classes that inherit from
      # classes that have been configured also inherit
      # the configuration of the parent class
      #
      def inherited subclass
        subclass.superclass.class_eval do
          subclass.configuration.data.merge!  subclass.superclass.configuration.data
          subclass.configuration.tasks.merge! subclass.superclass.configuration.tasks
        end
      end

    end
  end
end