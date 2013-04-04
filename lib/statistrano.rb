# required libraries
require 'net/ssh'
require 'colorize'
require 'json'
require 'fileutils'
require 'slugity/extend_string'

# required modules
# require 'statistrano/base'
require 'statistrano/deployment'
require 'statistrano/deployment/releases'
require 'statistrano/deployment/branches'
require 'statistrano/utility'
require 'statistrano/git'
require 'statistrano/log'


# DSL for defining server servers
#
# == Define a server
#
#     define_server "foo" do
#       set :attribute, "value"
#     end
#
# == Attributes
#
# [+:remote (String)+] The hostname or or ip of the remote
# [+:user (String)+] The user to authenticate as
# [+:password (String)+] The user's password
# [+:keys (Array)+] List of local keys
# [+:forward_agent (Boolean)+] Run ssh forward agent
# [+:base_domain (String)+] Domain to base release links off
# [+:build_task (String)+] The rake task to invoke locally
# [+:releases (Boolean)+] Whether to use the release system or not
# [+:release_count (Integer)+] Number of releases to keep on remote
# [+:release_dir (String)+] The folder name of where to keep releases on the remote
# [+:public_dir (String)+] The name of the symlinked folder on the remote
# [+:local_dir (String)+] The local directory to rsync to the remote
# [+:project_root (String)+] The root directory on the remote
# [+:git_check_branch (String)+] The git branch to check with +:git_checks+
module Statistrano

  # Define a deployment
  # @param [String] name of the deployment
  # @param [Symbol] type of deployment
  # @return [Statistrano::Deployment::Base]
  def define_deployment name, type=:base

    begin
      @deployment = Statistrano::Deployment.const_get(type.to_s.capitalize).new( name )
    rescue NameError
      LOG.error "The deployment type '#{type}' is not defined"
    end

    yield(@deployment.config) if block_given?
    return @deployment

  end

end

include Statistrano