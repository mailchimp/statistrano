module Statistrano
  module Deployment

      module RakeTasks
        class << self

          # Add rake tasks
          include ::Rake::DSL

          # Register the rake tasks for the deployment
          # @return [Void]
          def register deployment
            rake_namespace = deployment.name.to_sym
            deployment.config.tasks.each do |task_name, task_attrs|
              in_namespace rake_namespace do
                register_task deployment, task_name, task_attrs
              end
            end
          end

          private

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

        end
      end

  end
end
