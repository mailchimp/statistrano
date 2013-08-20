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