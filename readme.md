Description
===========

A gem to simplify the deployment of static sites, and staging of feature branches.



Installation
============

With Bundler
```ruby
gem "statistrano", git: "git@github.com:mailchimp/statistrano.git",
                   tag: "1.0.0"
```


Examples
========

### Base deployment

The base setup simply copies a local directory to a remote directory

```ruby
# deploy.rake
require 'statistrano'

deployment = define_deployment "basic" do

  hostname   'remote_name'
  user       'freddie' # optional if remote is setup in .ssh/config
  password   'something long and stuff' # optional if remote is setup in .ssh/config

  remote_dir '/var/www/mailchimp.com'
  local_dir  'build'
  build_task 'middleman:build' # optional if nothing needs to be built
  post_deploy_task 'base:post_deploy' # optional if no task should be run after deploy

  dir_permissions  755 # optional, the perms set on rsync & setup for directories
  file_permissions 644 # optional, the perms set on rsync & setup for files

  check_git  true # optional, set to false if git shouldn't be checked
  git_branch 'master' # which branch to check against

  # optional, you can define multiple remotes to deploy to
  # any config option can be overriden in the remote's data hash
  remotes [
    { hostname: 'remote01', remote_dir: '/var/www/mailchimp01' },
    { hostname: 'remote02', remote_dir: '/var/www/mailchimp02' }
  ]

end
```

**Rake Tasks**

Once a deployment is defined, you can register it's tasks -- or call the methods directly.

```ruby
# deploy.rake
deployment.register_tasks
# => rake tasks are registered
```

`rake basic:deploy`  
deploys the local_dir to the remote_dir. optionally call `deployment.deploy`


### Releases deployment

Out of the box Statistrano allows you to pick from a release based deployment, or branch based. Releases act as a series of snapshots of your project with the most recent linked to the `public_dir`. You can quickly rollback in case of errors.

```ruby
# deploy.rake
require 'statistrano'

deployment = define_deployment "production", :releases do

  # in addition to the "base" config options, there
  # are some (all defaulted) options specific for releases
  release_count 5
  release_dir  "releases"
  public_dir   "current"

end
```

**Rake Tasks**

Once a deployment is defined, you can register it's tasks -- or call the methods directly.

```ruby
# deploy.rake
deployment.register_tasks
# => rake tasks are registered
```

`rake production:deploy`  
deploys local_dir to the remote, and symlinks remote_dir/current to the release.

`rake production:rollback`  
rolls back to the previous release.

`rake production:prune`  
manually removes old releases beyond the release count

`rake production:list`  
lists all the currently deployed releases


### Branch deployment

The branch deployment type adds some nice defaults to use the current branch as your release name. So with the correct nginx/apache config you can have your branches mounted as subdomains (eg: `http://my_awesome_branch.example.com`). Aditionally it is set up to create an `index` release that shows a list of your currently deployed branches.


```ruby
deployment = define_deployment "branches", :branches do

  # in addition to the "base" options
  base_domain "mailchimp.com" # used to generate the subdomain links in the index file
  public_dir  "current_branch" # defaults to a slugged version of the current branch
  post_deploy_task "name:generate_index" # defaults to create the index file

end
```

**Rake Tasks**

Once a deployment is defined, you can register it's tasks -- or call the methods directly.

```ruby
# deploy.rake
deployment.register_tasks
# => rake tasks are registered
```

`rake branches:deploy`  
deploys local_dir to the remote named for the current git branch, and generates an index page

`rake branches:list`  
lists all the currently deployed branches

`rake branches:open`  
If you have set a base_domain, opens the branch in your default browser

`rake branches:prune`  
shows list of currently deployed branches to pick from and remove

`rake branches:generate_index`  
manually kicks of index generation, typically you shouldn't need to do this


## Build & Post Deploy Tasks

Of note, the `build_task` & `post_deploy_task` can be defined as a block. Some release types (like "releases") will use a hash if it is returned by the block.

```ruby
deployment = define_deployment 'multi', :releases do
  build_task do
    Rake::Task['build'].invoke
    { commit: Asgit.current_commit }
  end
end

deployment.deploy
# => remote/manifest.manifest will end up with [{release: 'timestamp', commit: 'commit_sha'}]
```

You can also access the current deployment info by giving the block arity.

```ruby
deployment = define_deployment 'multi', :releases do
  build_task do |dep|
    puts dep.name
  end
end

deployment.invoke_build_task
# => will output the deployment name 'multi'
```

### Config Syntax

In addition to the "DSL" way of configuring, the `define_deployment` block will yield the config if an argument is passed. You can use this if you need to do any specific manipulation to config (is also the "old" syntax).

```ruby
define_deployment "basic" do |config|

  config.remote     =  'remote_name'
  config.remote_dir =  '/var/www/mailchimp.com'
  config.local_dir  =  'build'

end
```


Testing
=======

Tests are written in rspec, and can be run with `rspec`. To run an individual test, run `rspec path/to/spec.rb`.

Integraton tests run through `localhost`, this requires that you setup ssh through localhost to run the tests. Look at [setup](#setup) for help with that.


### Setup

On Mac OS X 10.8, you should enable remote login.

```
System Preferences -> Sharing -> Turn on Remote Login
```

And setup your `.ssh/config`

```
Host localhost
  HostName localhost
  User {{your_username}}
```

Then add your pub key to `.ssh/authorized_keys`.

Depending on how you've setup your `.bashrc` is setup, you may need to move any PATH manipulation to the front of the file to prevent commands from failing.


### Test accross multiple rubies

To run specs accross the supported rubies, run `bin/multi_ruby_rspec`


Contributing
============

If there is any thing you'd like to contribute or fix, please:

- Fork the repo
- Add tests for any new functionality
- Make your changes
- Verify all existing tests work properly
- Make a pull request


License
=======
The statistrano gem is distributed under the MIT License.