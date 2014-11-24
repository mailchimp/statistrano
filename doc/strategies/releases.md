---
title: Releases Strategy
---

The Releases strategy is really made for production environments. If you are familiar with the way [Capistrano](https://github.com/capistrano/capistrano) works, it is very similar. Deploys work by creating a new "release" directory with fresh code, then symlinking that to the "current" directory. It's a little different from Capistrano in that it doesn't really care about the remote environment, it just runs the commands you give it.

Did you botch a release? No big deal™. You can rollback to the previous state while you fix the mistake. This strategy also provides a facility for storing a little bit of metadata about each release. (more on that later).

### Example:

```ruby
# tasks/deploy.rake
require 'statistrano'

deployment = define_deployment "production", :releases do

  # in addition to the "base" config options, there
  # are some (all defaulted) options specific for releases

  # the release_count defines how many releases to store in
  # history, more releases gives you more history to rollback
  # but takes up more space
  release_count 5

  # each release creates it's own directory inside the
  # release_dir so it's full path would be:
  # /#{remote_dir}/releases/#{release_number}
  release_dir  "releases"

  # combined with the `remote_dir`, `public_dir` defines the
  # the directory that gets symlinked to, point your docroot here:
  # #{remote_dir}/#{public_dir}
  public_dir   "current"

  # allows a task to run before the symlink gets updated
  # you might use this to run tests on the target servers
  pre_symlink_task do |deployment, releaser|
    deployment.remotes.each_with_object([]) do |r,status|
      resp = r.run "#{releaser.release_path}/bin/test_something"
      status.push resp.success?
    end.all? { |i| i }
  end

end
```

Like base deployments, we need to register the rake tasks if we'd like the defaults to be available.

```ruby
deployment.register_tasks
```

In addition to `deploy` we get a few more utilities for managing releases.

`rake production:rollback`  
rolls back to the previous release.

`rake production:prune`  
manually removes old releases beyond the release count

`rake production:list`  
lists all the currently deployed releases


### Build Metadata

Releases are managed using a manifest on the remote, and there is a facility to add more data to this manifest for each release. If your build_task returns a hash, it will be merged in to be stored with the release.

```ruby
define_deployment "production", :releases do

  # other config ...

  build_task do
    BuildScript("production")
    # => { time: 60, css: "145kb", whoami: 'freddie' }
  end

  # now on deploy, along with the release name,
  # the time, css, and whoami keys will be stored

end
```

### With PHP

PHP has [been known to have problems](http://stackoverflow.com/questions/18450076/capistrano-symlinks-being-cached) updating to newer symlinks. So it's a good idea to "kick the tires" in a `post_deploy_task` if this may be a problem for you. In this case, reloading php with fpm.

```ruby
define_deployment "production", :releases do

  post_deploy_task do |deployment|
    deployment.remotes.each do |remote|
      remote.run "service php-fpm reload"
    end
  end

  # other config...
end
```
