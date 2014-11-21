module Statistrano
  class Config

    module RakeTaskWithContextCreation

      def self.included base
        base.module_eval do
          def user_task_namespaces
            @_user_task_namespaces ||= []
          end

          def user_tasks
            @_user_tasks ||= []
          end
        end
      end

      def task_namespace namespace, &block
        context = Context.new (user_task_namespaces + [namespace])
        context.instance_eval &block
        user_tasks.push *context.user_tasks
      end

      def task name, &block
        user_tasks.push name: name,
                        namespaces: user_task_namespaces,
                        block: block
      end

      class Context
        include RakeTaskWithContextCreation

        def initialize namespaces=[]
          @_user_task_namespaces = namespaces
        end
      end
    end

  end
end
