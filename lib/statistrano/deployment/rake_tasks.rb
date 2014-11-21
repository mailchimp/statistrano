module Statistrano
  module Deployment

      module RakeTasks
        class << self

          # Add rake tasks
          include ::Rake::DSL

          # Register the rake tasks for the deployment
          # @return [Void]
          def register deployment
            deployment.config.tasks.each do |task_name, task_attrs|
              in_namespace rake_namespace(deployment) do
                register_task deployment, task_name, task_attrs
              end
            end

            deployment.config.user_tasks.each do |task_obj|
              in_namespace rake_namespace(deployment) do
                register_in_namespace_recursive deployment,
                                                task_obj[:name],
                                                task_obj[:namespaces],
                                                task_obj[:block]
              end
            end
          end

          private

            def rake_namespace deployment
              deployment.name.to_sym
            end

            def in_namespace namespace, &block
              namespace namespace do
                yield
              end
            end

            def register_task deployment, task_name, attrs={}
              desc attrs[:desc]
              task task_name do
                deployment.public_send attrs[:method]
              end
            end

            def register_in_namespace_recursive deployment, task_name, task_space, block
              if task_space.empty?
                register_user_task deployment, task_name, block
              else
                in_namespace task_space.shift do
                  register_in_namespace_recursive deployment, task_name, task_space, block
                end
              end
            end

            def register_user_task deployment, task_name, block
              task task_name do
                if block.arity == 1
                  block.call deployment
                else
                  block.call
                end
              end
            end

        end
      end

  end
end
