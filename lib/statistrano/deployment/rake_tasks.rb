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
          end

          def register_user_task deployment, *task_name_and_space, &block
            task_name   = task_name_and_space.pop
            task_space  = task_name_and_space.unshift rake_namespace(deployment)

            register_in_namespace_recursive deployment, task_name, task_space, block
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
              in_namespace task_space.shift do
                if task_space.empty?
                  task task_name do
                    if block.arity == 1
                      block.call deployment
                    else
                      block.call
                    end
                  end
                else
                  register_in_namespace_recursive deployment, task_name, task_space, block
                end
              end
            end

        end
      end

  end
end
