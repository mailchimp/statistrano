# required libraries
require 'net/ssh'
require 'colorize'
require 'json'
require 'fileutils'

# required modules
require 'statistrano/base'
require 'statistrano/utility'
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
# [+:build_task (String)+] The rake task to invoke locally
# [+:releases (Boolean)+] Whether to use the release system or not
# [+:release_count (Integer)+] Number of releases to keep on remote
# [+:release_dir (String)+] The folder name of where to keep releases on the remote
# [+:public_dir (String)+] The name of the symlinked folder on the remote
# [+:local_dir (String)+] The local directory to rsync to the remote
# [+:project_root (String)+] The root directory on the remote
# [+:git_check_branch (String)+] The git branch to check with +:git_checks+
module Statistrano

  # The main Statistrano class
  class << self
    # @param [String] name
    # @return [Object] The added server
    def new(name)
      @_servers ||= []
      @_servers << Base.new(name)
      @_servers.last
    end

    # Get all of the added servers
    # @return [Hash] List of added servers
    def all
      @_servers
    end
  end

  # Define a server server
  # @param [Symbol] name The name of the server
  # @return [Void]
  def define_server name # :yields: :server
    @server = Statistrano.new(name)
    yield(@server) if block_given?
  end

  # Set an argument with a value for a server
  # @param [Symbol] arg The server argument
  # @param [String] value The argument value
  # @return [Void]
  def set arg, value
    @server.send "#{arg.to_sym}=", value
  end

end

include Statistrano