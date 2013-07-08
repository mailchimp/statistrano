module Statistrano
  module Deployment

      module RakeTasks
        class << self

          # Add rake tasks
          include ::Rake::DSL

          # Register the rake tasks for the deployment
          # @return [Void]
          def register deployment
            register_namespace deployment.name.to_sym do
              register_tasks deployment
            end
          end

          private

            def register_namespace name, &block
              namespace(name) do
                yield
              end
            end

            def register_tasks deployment
              deployment.config.tasks.each do |task_name,task_attrs|
                register_task deployment, task_name, task_attrs
              end
            end

            def register_task deployment, name, attrs={}
              desc attrs[:desc]
              task name do
                deployment.run_action attrs[:method]
              end
            end

        end
      end

  end
end
