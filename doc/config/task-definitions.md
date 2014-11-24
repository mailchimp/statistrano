---
title: Task Definitions
---

These are the `build_task` and `post_deploy_task` setup in a deployment's config. They are flexible allowing you to set them as a block or a string to call a rake task.

You can also create your own tasks that have access to the Statistrano deployment & remotes.


### Call a Rake Task

```ruby
define_deployment "example" do

  build_task "base:build"
  # this will call `Rake::Task['base:build'].invoke`

end
```


### Run a Block

Without any need for deployment context:

```ruby
define_deployment "example" do

  build_task do
    # run our block of code
    BuildScript("example")
    # => { foo: "bar", wu: "tang" }

    # if we return a hash, depending on the deployment
    # strategy it may use that build metadata
  end

end
```

If we need the deployment object for context:

```ruby
define_deployment "example" do

  build_task do |deployment|
    # by giving the task arity we can access the
    # deployment object

    deployment.name
    # => example
  end

end
```

### Define Your Own Tasks

For this we have two methods usable in the configuration blog, `namespace` and `task`.

`namespace` wraps any tasks (or other namespaces) you define to allow creating a sane structure to your new tasks.

`task` creates a new task with name & description. Like the `build_task` and `post_deploy_task` if you give your block arity you'll be able to access the deployment.

An example:
```ruby
example = define_deployment "example" do
  task :test_connections, 'test connection to the remotes' do |deployment|
    deployment.remotes.each(&:test_connection)
  end

  namespace :php do
    task :restart, 'restart php-fpm on each remote' do |deployment|
      deployment.remotes.each do |r|
        r.run "sudo php-fpm restart"
      end
    end
  end
end
example.register_tasks
```

This will give you tasks that look like this:
```bash
$ rake -T
example:test_connections  # test connection to the remotes
example:php:restart       # restart php-fpm on each remote
```
