---
title: Getting Started
---

## Installation

Add to your Gemfile:

```ruby
gem "statistrano", git: "git@github.com:mailchimp/statistrano.git",
                   tag: "1.0.0"
```

Bundle:

```bash
$ bundle install
```


## Setting up a deployment

In a Rakefile (typically `tasks/deploy.rake`) we'll require statistrano then define an example deployment.

```ruby
# tasks/deploy.rake
require 'statistrano'

example = define_deployment "example", :base do

  # first we setup the host we deploy to,
  # we will have set this up in ~/.ssh/config so we
  # can ssh to it using a pubkey as auth
  hostname 'digitalocean'

  # now we'll configure the source and target directories
  local_dir  'build'
  remote_dir '/opt/example'

  # we have access to two task hooks, the build_task
  # and the post_deploy_task. they can work in two different ways:
  #   1. if given a string, they call a rake task
  #   2. if given a block they run that block when called,
  #      see the build task guide for more information
  #
  # in this case we'll run the block
  build_task do |deployment|
    # it's good to check if your connections are all valid
    deployment.remotes.each(&:test_connection)

    ENV['BUILD_ENV'] = "example"
    Rake::Task['middleman:build'].invoke
  end
  # and just call the rake task here
  post_deploy_task 'middleman:cleanup'

  # statistrano can guard agains errant deploys that aren't
  # checked into version control. we just have to give it the
  # branch we want to check against
  check_git  true
  git_branch 'master'

  # there is support for deploying to multiple remotes
  # simultaniously, any config option can be overriden for an
  # individual remote in it's option hash
  remotes [
    { hostname: 'remote01', remote_dir: '/var/www/mailchimp01' },
    { hostname: 'remote02', remote_dir: '/var/www/mailchimp02' }
  ]
end
```

We don't have any rake tasks set up now though, as they aren't registered by default. Calling the `register_tasks` method on the deployment will set up the default ones.

```ruby
example.register_tasks
```

Though in some cases you may want to skip that and register them manually (like if you need to set specific env variables).

Now to deploy you'd run `rake example:deploy`.

For more information on specific, check out the guides below.

## Strategies

- [Base](/doc/strategies/base.md)
- [Revisions](/doc/strategies/revisions.md)
- [Branches](/doc/strategies/branches.md)


## Configuration

- [Task Definitions](/doc/config/task-definitions.md)
- [File Permissions](/doc/config/file-permissions.md)
- [Log Files](/doc/config/log-files.md)
