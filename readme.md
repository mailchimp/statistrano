Description
===========

A gem to simplify the deployment of static sites, and staging of feature branches.



Installation
============

With Bundler
```ruby
gem 'statistrano', :git => 'git@github.com:mailchimp/statistrano.git'
```


Examples
========

### Basic production deployment
This setup creates tasks under the namespace `production`. If you have your pub keys setup for ssh, you can (and probably should) leave off :user and :password.

Seting :git_check_branch to "master" ensures that your working tree is clean, you're in sync with the remote, and that you're working off the master branch.

```ruby
# deploy.rake
require 'statistrano'

define_server "production" do
  set :remote, 'servername'
  set :user, 'freddie' # optional
  set :password, "something long and safe and stuff" # optional
  set :project_root, "/var/www/mailchimp.com"
  set :git_check_branch, "master"
end
```
To create a new release/deploy run:
```bash
$ rake production:deploy
```

### Feature branch deployment
This setup doesn't create releases, but instead deploys to a directory with a slugged version of the branch name. As long as your nginx/apache configs are setup you can visit `your-branch-name.yourdomain.com` to view your feature branch.

```ruby
# deploy.rake
require 'statistrano'

define_server "feature_branch" do
  set :remote, 'servername'
  set :user, 'freddie' # optional
  set :password, "something long and safe and stuff" # optional
  set :releases, false
  set :project_root, "/var/www/branches.mailchimp.com"
  set :public_dir, Statistrano::Util.current_git_branch.to_slug
  set :git_check_branch, Statistrano::Util.current_git_branch
end
```

Testing
=======

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