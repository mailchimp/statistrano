---
title: Task Definitions
---

These are the `build_task` and `post_deploy_task` setup in a deployment's config. They are flexible allowing you to set them as a block or a string to call a rake task.

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