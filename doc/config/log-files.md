---
title: Log Files
---

You can specify a log file to store a record of every deploy. These logs could eventually get pretty large, so it's suggested you point logrotate at the log files to keep them in check.

The data that is stored for each release is completely up to you, and definable with the `log_file_content` method. It will accept an argument for the `deployment`, `releaser`, `build_data`, and `post_deploy_data` and expects a hash to be returned (or an object with to_json).

Here we'll use [Asgit](https://github.com/stevenosloan/asgit) to create a model of our projects repo urls. Lets pretend our project is called `caesar` on github.

```ruby

repo = Asgit::Project.new service:        :github,
                          organization:   'mailchimp',
                          project:        'caesar',
                          default_branch: 'master'


define_deployment "caesar" do

  build_task do |deployment|
    # do some work

    # return data from build
    {
      commit:          Asgit.current_commit,
      previous_commit: deployment.persisted_releaser
                                 .current_release_data(
                                    deployment.remotes.first
                                 )[:commit]
      # etc ...
    }
  end

  log_file_path "/var/log/caesar.deploy.log"
  log_file_entry do |deployment, releaser, build_data, post_deploy_data|
    {
      time:     releaser.release_name,
      deployer: `whoami`,
      diff_url: repo.urls.compare( Asgit.current_commit,
                                   build_data.delete(:previous_commit) )
    }.merge(build_data)
  end

end
