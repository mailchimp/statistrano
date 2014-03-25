---
title: Base Strategy
---

As it's name would imply, the `base` strategy is just that, a base. Each of the other strategies build off of it, that doesn't mean it's not useful though. It can still move your code to a target location on multiple remotes.

This strategy will take the contents of the defined `local_dir` and sync them to the `remote_dir` on your remotes.

### Example:

```ruby
# tasks/deploy.rake
require 'statistrano'

example = define_deployment "example", :base do

  hostname 'digitalocean'

  local_dir  'build'
  remote_dir '/opt/example'

  build_task do |deployment|
    deployment.remotes.each(&:test_connection)
    Rake::Task['middleman:build'].invoke
  end

  post_deploy_task 'middleman:cleanup'

  check_git  true
  git_branch 'master'

  remotes [
    { hostname: 'remote01', remote_dir: '/var/www/mailchimp01' },
    { hostname: 'remote02', remote_dir: '/var/www/mailchimp02' }
  ]

end
```