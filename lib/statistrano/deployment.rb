# deployment utils
require 'statistrano/deployment/manifest'
require 'statistrano/deployment/rake_tasks'

module Statistrano
  module Deployment

    class << self

      def types
        @_types ||= {}
      end

      def register_type deployment, name
        types[name.to_sym] = deployment
      end

      def find name
        types.fetch(name.to_sym) do
          raise UndefinedDeployment, "no deployments are registered as :#{name}"
        end
      end

    end

    module Registerable
      def register_type name
        Deployment.register_type( self, name )
      end
    end

    class UndefinedDeployment < StandardError
    end

  end
end


# deployment types
require 'statistrano/deployment/base'
require 'statistrano/deployment/releases'
require 'statistrano/deployment/branches'
