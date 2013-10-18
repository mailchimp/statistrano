# required libraries
require 'net/ssh'
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
require 'statistrano/ssh'

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

    begin
      @deployment = ::Statistrano::Deployment.const_get(type.to_s.capitalize).new( name )
    rescue NameError => e
      ::Statistrano::LOG.error "The deployment type '#{type}' is not defined\n#{e.backtrace}"
    end

    if block_given?
      if block.arity == 1
        yield @deployment.config
      else
        @deployment.config.instance_eval &block
      end
    end

    return @deployment
  end

end

include Statistrano::DSL