module Statistrano
  module Deployment
    module Strategy

      module InvokeTasks

        # Run the post_deploy_task
        # return [Void]
        def invoke_post_deploy_task
          if config.post_deploy_task
            Log.info :post_deploy, "Running the post deploy task"
            call_or_invoke_task config.post_deploy_task
          end
        end

        # Run the build_task supplied
        # return [Void]
        def invoke_build_task
          Log.info :build, "Running the build task"
          call_or_invoke_task config.build_task
        end

        def call_or_invoke_task task
          if task.respond_to? :call
            task.call
          else
            Rake::Task[task].invoke
          end
        rescue Exception => e
          Log.error "exiting due to error in task",
                    "#{e.class}: #{e}"
          abort()
        end

      end

    end
  end
end