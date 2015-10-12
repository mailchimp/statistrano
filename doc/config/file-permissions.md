---
title: File Permissions
---

In some cases you may be deploying into an environment where the default chmod settings of 755 for directories and 644 for files isn't appropriate. Lucky for you, there's a setting for that :).

For example if we'd like to deploy to a server using different users that are part of the same group:

```ruby
define_deployment "example" do

  # set the permissions directories will be
  # created with
  dir_permissions 775

  # set the permissions files will be
  # created with
  file_permissions 664

end
```

Using `775` and `664` is ok if the deployment members are part of the same group, but unless you're using the `releases` deployment strategy you'll run into trouble when rsync tries to update the timestamps on directories. You *must* be the owner of the directory to do that. Getting around that little caveat we can configure the rsync flags to skip updating timestamps:

```ruby
define_deployment "example" do

  rsync_flags "-aqz " + # archive, quiet, & compress
              "-O "   + # omit timestamp updates from directories
              "--delete-after" # remove orphaned files *after* the sync is complete

end
```


If you are running rsync 3.1.0+ locally & on the remote you can also set the owner of the files. Look at the [rsync man page](https://download.samba.org/pub/rsync/rsync.html) for `chown`, `groupmap`, or `usermap` for more information on how this works.

To configure set `dir_user` or `dir_group` on your deployment.

```ruby
define_deployment "example" do
  dir_group 'deploy'
end
```

