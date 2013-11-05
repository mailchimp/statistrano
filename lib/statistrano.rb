# required libraries
require 'colorize'
require 'json'
require 'fileutils'
require 'rake'
require 'slugity/extend_string'
require 'benchmark'
require 'here_or_there'

# utility modules
require 'statistrano/shell'
require 'statistrano/git'
require 'statistrano/log'

# deployment modules
require 'statistrano/config'
require 'statistrano/deployment'


# DSL for defining deployments of static files
#
# == Define a server
#
#     define_deployment "foo" do |config|
#       config.attribute = value
#     end
#
module Statistrano::DSL

  # Define a deployment
  # @param [String] name of the deployment
  # @param [Symbol] type of deployment
  # @return [Statistrano::Deployment::Base]
  def define_deployment name, type=:base, &block
    deployment = ::Statistrano::Deployment.const_get(type.to_s.capitalize).new( name )

    if block_given?
      if block.arity == 1
        yield deployment.config
      else
        deployment.config.instance_eval &block
      end
    end

    return deployment
  rescue NameError => e
    ::Statistrano::LOG.warn "The deployment type '#{type}' is not defined"
    raise e
  end

end

include Statistrano::DSL