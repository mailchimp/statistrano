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

              deployment.config.tasks.each do |task_name,task_attrs|
                desc task_attrs[:desc]
                task task_name do
                  deployment.prepare_for_action
                  deployment.send(task_attrs[:method])
                end
              end

            end

          end

        end
      end

  end
end
