Description
===========

A gem to simplify the deployment of static sites, and staging of feature branches.



Installation
============

With Bundler
```ruby
gem "statistrano", git: "git@github.com:mailchimp/statistrano.git"
```


Examples
========

### Base deployment
The base setup simply copies a local directory to a remote directory

```ruby
# deploy.rake
require 'statistrano'

define_deployment "basic" do

  remote     'remote_name'
  user       'freddie' # optional if remote is setup in .ssh/config
  password   'something long and stuff' # optional if remote is setup in .ssh/config

  remote_dir '/var/www/mailchimp.com'
  local_dir  'build'
  build_task 'middleman:build' # optional if nothing needs to be built

  check_git  true # optional, set to false if git shouldn't be checked
  git_branch 'master' # which branch to check against

end
```

**Tasks**

`rake basic:deploy`  
deploys the local_dir to the remote_dir

**Environment**

The deployment environment is available to tasks called by Statistrano under the env variable `DEPLOYMENT_ENVIRONMENT`.

```ruby
# ruby
ENV["DEPLOYMENT_ENVIRONMENT"]
# => "basic"
```

```bash
# bash
echo $DEPLOYMENT_ENVIRONMENT
# => basic
```


### Releases deployment
Out of the box Statistrano allows you to pick from a release based deployment, or branch based. Releases act as a series of snapshots of your project with the most recent linked to the `public_dir`. You can quickly rollback in case of errors.

```ruby
# deploy.rake
require 'statistrano'

define_deployment "production", :releases do

  remote      'remote_name'
  build_task  'middleman:build'
  local_dir   'build'
  remote_dir  '/var/www/mailchimp.com'

end
```

**Tasks**

`rake production:deploy`  
deploys local_dir to the remote, and symlinks remote_dir/current to the release

`rake production:rollback`  
rolls back to the previous release

`rake production:prune`  
manually removes old releases beyond the release count

`rake production:list`  
lists all the currently deployed releases


### Branch deployment
The branch deployment type adds some nice defaults to use the current branch as your release name. So with the correct nginx/apache config you can have your branches mounted as subdomains (eg: `http://my_awesome_branch.example.com`). Aditionally it is set up to create an `index` release that shows a list of your currently deployed branches.


```ruby
define_deployment "branches", :branches do

  remote      'remote_name'
  build_task  'middleman:build'
  local_dir   'build'
  remote_dir  '/var/www/mailchimp.com'
  base_domain "mailchimp.com"

end
```

**Tasks**

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

Integraton tests run through `localhost`, this requires that you setup ssh through localhost to run the tests. Look at [setup](#setup) for help with that.

Tests are written in rspec, and can be run with `rspec`. To run an individual test, run `rspec path/to/spec.rb`.

[Reek](https://github.com/troessner/reek) is also included in the bundle to check for some code smells. Run `reek lib/*` to check the whole lib directory.


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