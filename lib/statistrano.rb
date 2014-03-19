# stdlib
require 'json'
require 'forwardable'
require 'fileutils'
require 'benchmark'

# libraries
require 'rainbow'
require 'rake'
require 'slugity/extend_string'
require 'here_or_there'
require 'asgit'

# utility modules
require 'statistrano/util'
require 'statistrano/shell'
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
    deployment = ::Statistrano::Deployment.find(type).new( name )

    if block_given?
      if block.arity == 1
        yield deployment.config
      else
        deployment.config.instance_eval &block
      end
    end

    return deployment
  end

end

include Statistrano::DSL