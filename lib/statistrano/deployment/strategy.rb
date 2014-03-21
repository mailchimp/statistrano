module Statistrano
  module Deployment
    module Strategy

      class << self

        def registered
          @_registered ||= {}
        end

        def register deployment, name
          registered[name.to_sym] = deployment
        end

        def find name
          registered.fetch(name.to_sym) do
            raise UndefinedStrategy, "no strategies are registered as :#{name}"
          end
        end

      end

      class UndefinedStrategy < StandardError
      end

    end
  end
end

# strategy utils
require_relative 'strategy/invoke_tasks'
require_relative 'strategy/check_git'

# strategies
require_relative 'strategy/base'
require_relative 'strategy/branches'
require_relative 'strategy/multi_target'
require_relative 'strategy/releases'