---
title: Branches Strategy
---

Inspired by layervault's [Divergence](http://cosmos.layervault.com/divergence.html), the Branches strategy is special built for staging all the things. It will do a base deploy to a subdirectory based on the current git branch, then generate and index w/ all of the currently staged branches. With the correct bit of nginx (or apache) setup each branch is accessible from a subdomain.

### Example

```ruby
deployment = define_deployment "branches", :branches do

  # in addition to the "base" options

  # the allow the generated index properly create links to the
  # subdomains, we need to give it a base to work off of
  base_domain "mailchimp.com"

  # the public_dir is the subdir under remote_dir where the site
  # will be deployed, for branch based locations *don't* touch this
  # but if we want to mount a different project we can manually manipulate this
  public_dir  "current_branch"

  # the post deploy task defaults to generating the index file
  # and adding the current_release to the manifest
  # so if you touch this keep that in mind as you may want to
  # generate that as well
  post_deploy_task do |deployment|
    d.push_current_release_to_manifest
    d.generate_index
  end

end
```

Like base deployments, we need to register the rake tasks if we'd like the defaults to be available.

```ruby
deployment.register_tasks
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


### NGINX configs

Set up your configs to pass the subdomain down as the docroots, here's some relavent configs:

```nginx
server {
  listen 80;
  server_name ~^(?<subdomain>.*)\.yourdomain.com;

  # use the subdomain captured above in the docroot
  root /var/www/branches.yourdomain.com/$subdomain;
  index index.html index.htm index.php;

  # pass the subdomain to fastcgi as well
  location ~ \.php$ {
      #fastcgi_pass 127.0.0.1:9000;
      # With php5-fpm:
      fastcgi_pass unix:/var/run/php5-fpm.sock;
      fastcgi_index index.php;
      include fastcgi_params;
      fastcgi_param SCRIPT_FILENAME /var/www/branches.yourdomain.com/$subdomain$fastcgi_script_name;
  }

  # other nginx stuf ..
}
```
