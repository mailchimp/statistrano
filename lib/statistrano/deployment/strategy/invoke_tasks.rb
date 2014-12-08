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

        # Run the pre_symlink_task if supplied
        # return [Void]
        def invoke_pre_symlink_task remote
          if !remote.config.pre_symlink_task.nil?
            Log.info :pre_symlink, "Running the pre_symlink task"
            resp = call_or_invoke_task remote.config.pre_symlink_task, remote
            if resp == false
              Log.error :pre_symlink, "exiting due to falsy return"
              abort()
            end
          end
        end

        def call_or_invoke_task task, arg=nil
          if task.respond_to? :call
            if arg && task.arity == 2
              task.call self, arg
            elsif task.arity == 1
              task.call self
            else
              task.call
            end
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
