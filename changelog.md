# 1.1.0
- `#persisted_releaser` is available on a deployment from rake tasks. this will be the same for tasks called during a deploy for example.
- addition of a `#current_release_data` method for the Revisions releaser. This pulls merged data from the manifest and the log file.
- add `log_file_path` and `log_file_entry` to config to setup a log file for all deploys
- [BREAKING] change interface of releasers to expect being able to pass a second argument (build data) to #create_release
- add task hook for before the symlink in the Revisions releaser. `pre_symlink_task` gets called with |releaser, remote| in a remote loop so it's run for each.
- add ability to create user rake tasks that have access to deployment information. see [the docs](doc/config/task-definitions.md) for more info

# 1.0.2
- make sure that Revisions#remove_untracked_revisions checks it against the "current" revision before removing it.

# 1.0.1
- add a second check to git after the build task to ensure build doesn't affect checked in files

# 1.0.0
- base includes a `deployment:build` and `deployment:post_deploy` task to allow direct triggering of these deployment steps
- add the `verbose` option for deployments
- fix bug in default logger to adjust for statuses that are too long
- create `Branches::Index` and render erb for the template
- move Branches specific ideas into the Branches namespace
- add `Deployment::Manifest#put` method to update manifest data for matching records
- remove `Statistrano::Deployment::Manifest` & `Statistrano::Deployment::Manifest::RemoteStore` in favor of using the same manifest as the Revisions releaser
- add option for rsync flags [b5a248be8d96d142ca94c076d80ad6deaa0fa69e]
- loosen rainbows dependency to work with old & new bananabin
- reorganize deployment types & releasers. now use a single remote object, and different "strategies" for base, releases, & branches and different "releasers" for single or revisions
- remote multi_target in favor of merging code paths w/ strategies & releasers
- can now access deployment info directly in build_tasks & post_deploy_tasks by giving arity [de05bb3a7d760fc51571b0f93f457065758fa772]
- rake tasks no manually registered (instead of on initialization) [ac72eb0a65681e472b21c486fa67f7f0dd635c02]
- add explicit setting for file & directory permissions on deploy [25ed930235e348fd6068cedbdc09b33e788fc3d5]

# 0.10.0
- tag release

# 0.10.0.rc3
- fix copy current release step, target needs to not exist

# 0.10.0.rc2
- copy current release to help reduce time spent rsyncing new build

# 0.10.0.rc1
- make dir with 775, so global (ngnx) can read them

# 0.10.0.beta3
- release dir created recursively, ensures permissions on releases dir
- add guard to not remove a currently symlinked release

# 0.10.0.beta2
- manifests check if they exist before trying to create themselves
- add Target#test_connection method to allow for early testing of remote connections
- MultiTarget post_deploy_task accepts blocks just like build_task
- add a "verbose" option to Target to log each command run

# 0.10.0.beta1
- add a "new architecture" MultiTarget deployment type
- fix Util::symbolize_hash_keys to work with nested hashes
- add a types cache and register methods for registering deployment types
- remove Git code (it wasn't being used)

# 0.9.1
- bump Asgit dependency to 0.1

# 0.9.0
- misc refactoring
- switch to Asgit for git status queries
- change the way ssh sessions are handled, now passed with the config
- using HereOrThere for running commands (has a consistent response object)

# 0.8.1
- fix nil error for manifest in branches

# 0.8.0
- re-architect configuration for deployment classes
- now suport a "sugar" dsl syntax for setting config while defining deployments

# 0.7.2
- fix bug where branch deployments would update timestamp on all branches in the manifest

# 0.7.1
- add an `open` rake task for Branches deployments to navigate to the url

# 0.7.0
- big refactoring to reduce complexity of the public methods

# 0.6.1
- fix a regression that caused Git.remote_up_to_date? to fail

# 0.6.0
- move a few setup methods
- add integration specs for the deployment modules
- add a spec for the git module
- rewrite Shell.run to use Open3 and improve output

# 0.5.3
- loosen all the dependencies

# 0.5.2
- loosen dependency on slugity

# 0.5.1
- add environment variable DEPLOYMENT_ENVIRONMENT set to the name of the deployment

# 0.5.0
- only create a single ssh connection for the deploy task (after_deploy creates a second)
- add exception handling to `invoke_build_task`, exit and log on an exception

# 0.4.1
- expose less of the statistrano namespace to help with conflicts of common names (like Log)

# 0.4.0
- now abort on errors

# 0.3.1
- add rake task descriptions
- add times for rsync task

# 0.3.0
- change rsync behavior, adds delete-after
- clone previous release first if it exits for release type deployments

# 0.2.2
- move setup to a `prepare_for_action` method, defer connection until needed

# 0.2.1
- regenerate index after pruning releases

# 0.2.0
- code overhaul
- new way to define deployments
- classes for different deployment types
- add pruning to branches deployments

# 0.1.3
- fix error with newlines in the current_git_commit

# 0.1.2
- updated apearance of index page

# 0.1.1
- add updated at to feature index page

# 0.1.0
- add post_deploy_task to servers
- add generate namespace, and generate:index task to rake tasks

# 0.0.4
- fix log order bug, standardize the printed output

# 0.0.3
- fixed bug with manifest for releases that have the same name

# 0.0.2
- fix manifest creation for feature releases
- add a releases:browse task

# 0.0.1
- initial gem creation
