module Statistrano
  module Deployment

      module RakeTasks
        class << self

          # Add rake tasks
          include ::Rake::DSL

          # Register the rake tasks for the deployment
          # @return [Void]
          def register deployment

            namespace deployment.name.to_sym do

              deployment.config.tasks.each do |task_name,method_name|
                task task_name do
                  deployment.send(method_name)
                end
              end

            end

          end

        end
      end

  end
end
