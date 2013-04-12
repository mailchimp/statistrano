# required libraries
require 'net/ssh'
require 'colorize'
require 'json'
require 'fileutils'
require 'rake'
require 'slugity/extend_string'

# utility modules
require 'statistrano/git'
require 'statistrano/log'

# deployment modules
require 'statistrano/deployment/ssh'
require 'statistrano/deployment'
require 'statistrano/deployment/manifest'
require 'statistrano/deployment/releases'
require 'statistrano/deployment/branches'
require 'statistrano/deployment/rake_tasks'


# DSL for defining deployments of static files
#
# == Define a server
#
#     define_deployment "foo" do |config|
#       config.attribute = value
#     end
#
module Statistrano

  # Define a deployment
  # @param [String] name of the deployment
  # @param [Symbol] type of deployment
  # @return [Statistrano::Deployment::Base]
  def define_deployment name, type=:base

    begin
      @deployment = Deployment.const_get(type.to_s.capitalize).new( name )
    rescue NameError
      LOG.error "The deployment type '#{type}' is not defined"
    end

    yield(@deployment.config) if block_given?
    @deployment.after_configuration
    return @deployment

  end

end

include Statistrano