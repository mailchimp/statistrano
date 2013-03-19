require 'statistrano/base/rake_tasks'

module Statistrano

  # A server instance
  class Base

    # @param [String] name Name of the server
    # @attribute name [String]
    attr_reader :name
    # @method remote [String]
    # @method user [String]
    # @method password [String]
    # @method keys [Array]
    # @method forward_agent [Boolean]
    attr_accessor :remote, :user, :password, :keys, :forward_agent
    # @method build_task [String]
    # @method releases [Boolean]
    # @method release_count [Integer]
    # @method release_dir [String]
    # @method public_dir [String]
    # @method local_dir [String]
    # @method project_root [String]
    attr_accessor :build_task, :releases, :release_count, :release_dir, :public_dir, :local_dir, :project_root
    # @method git_check_branch [String]
    attr_accessor :git_check_branch
    # @return [Void]
    def initialize(name)
      @name = name
      @releases             ||= true
      @release_count        ||= 5
      @release_dir          ||= 'releases'
      @public_dir           ||= 'current'
      @local_dir            ||= 'build'
      @build_task           ||= 'middleman:build'

      RakeTasks.register self
    end

    # Warn if deprecated argument is passed
    # @return [Void]
    def method_missing(meth, *args, &block)
      deprecated_args = [ :git_checks ]
      deprecated_args.each do |arg|
        if meth.to_s =~ /^#{arg}=$/
          LOG.error ":#{arg} is deprecated"
        else
          super
        end
      end
    end

    # Run ssh sync command and handle exceptions
    # @param [String] command the shell command to run
    # @return [Void]
    def run_ssh_command command # :yields: :channel, :stream, :data
      opts = {}
      [:user, :password, :keys, :forward_agent].each do |key|
        value = instance_variable_get("@#{key}")
        opts[key] = value if value
      end
      begin
        Net::SSH.start @remote, @user, opts do |ssh|
          ssh.exec command do |channel, stream, data|
            if stream == :stderr
              LOG.error "Error executing the command:\n\t\"#{command}\"" +
                        "\n" +
                        "\n\tRemote Error:\n\t#{data}"
              exit
            else
              yield(channel, stream, data) if block_given?
            end
          end
        end
      rescue Net::SSH::AuthenticationFailed
        puts "Authentication failed when connecting to '#{@remote}'".colorize :red
      end
    end

    # Deploy without git checks
    # @return [Void]
    def deploy
      LOG.msg "setting up #{name}", "deploying"
      build.invoke

      if @releases
        create_release
        prune_releases
      else
        release_to_public_path
      end

      LOG.msg "Cleaning up", nil
      FileUtils.rm_r local_path
    end

    # Deploy with git checks
    # @return [Void]
    def safe_deploy
      if !Util.working_tree_clean?
        LOG.error "You need to commit or stash your changes before deploying"
      # make sure you're on the branch selected to check against
      elsif Util.current_git_branch != @git_check_branch
        LOG.error "You shouldn't deploy from any branch but #{@git_check_branch}"
      # make sure you're up to date
      elsif !Util.remote_up_to_date?
        LOG.error "You need to update or push your changes before deploying"
      # do all that deployment stuff
      else
        deploy
      end
    end

    # create a single release at public path
    # used for doing feature branches
    # @return [Void]
    def release_to_public_path

      # Setup tasks for remote
      steps = []

      release_name = @public_dir

      # make sure release_path is created & create new release
      steps << { cmd: "mkdir -p #{public_path}", env: :remote, log: "Preparing release directory" }
      # rsync build to the @public_path
      host_connection = @user ? "#{@user}@#{@remote}" : @remote
      steps << { cmd: "rsync -avqz --delete-after -e ssh #{local_path}/ #{host_connection}:#{public_path}/", env: :local, log: "Syncing files to remote" }

      run_commands(steps)

      LOG.msg "Created release at #{public_dir}"
      add_manifest_release release_name

    end

    # Create a new release
    # @return [Void]
    def create_release

      # Setup tasks for remote
      steps = []
      # timestamp for release folder
      release_name = Time.now.strftime("%Y%m%d%H%M%S")
      current_release = File.join release_path, release_name

      # make sure release_path is created & create new release
      steps << {cmd: "mkdir -p #{current_release}", env: :remote, log: "Preparing release directory"}
      # rsync build to the @current_release
      host_connection = @user ? "#{@user}@#{@remote}" : @remote
      steps << {cmd: "rsync -avqz -e ssh #{local_path}/ #{host_connection}:#{current_release}/", env: :local, log: "Syncing files to remote"}
      # update symlink of @current_release -> current, the -nf option updates in place
      steps << {cmd: "ln -nfs #{current_release} #{public_path}", env: :remote, log: "Symlinking public_dir to release"}

      run_commands(steps)

      LOG.msg "Created release at #{public_dir}: #{release_name}"

      add_manifest_release release_name
    end

    # Rollback to last release
    # @return [Void]
    def rollback_release
      releases = get_manifest

      if releases.length > 1
        current_release = releases[0]
        past_release = releases[1]

        if run_ssh_command "ln -nfs #{release_path}/#{past_release['name']} #{@project_root}/#{@public_dir}"
          LOG.msg "Updated symlink to previous release (#{past_release['name']})"
        end

        if run_ssh_command "rm -rf #{release_path}/#{current_release['name']}"
          LOG.msg "Removed the most recent release (#{current_release['name']})"
        end

        remove_manifest_release(current_release['name'])
      else
        LOG.error "Whoa there, there's only one release -- you definetly shouldn't remove it"
      end
    end

    # Remove old releases
    # @return [Void]
    def prune_releases
      releases = get_manifest
      if releases && releases.length > @release_count
        releases[@release_count..-1].each do |release|
          LOG.msg "Removing old release (#{release['name']})"
          run_ssh_command "rm -rf #{release_path}/#{release['name']}"
          remove_manifest_release(release['name'])
        end
      else
        LOG.msg "No releases to prune"
      end
    end

    # Get all releases echoed to shell in table format
    # @return [Void]
    def get_releases
      manifest = get_manifest
      if manifest && manifest.length > 0
        cols = '| %-20s | %-20s | %-20s|\n'
        line = "echo '---------------------------------------------------------------------'"
        system line
        system "printf '#{cols}' 'Date' 'Name' 'Commit'"
        system line
        manifest.each do |release|
          name = release["name"]
          commit = release["commit"]
          date = Time.at(release["time"]).strftime("%D %r")
          system "printf '#{cols}' '#{date}' '#{name}' '#{commit[0..9]}'"
        end
      else
        puts "No releases exist"
      end
      return
    end

    private

      # run commands
      # @param steps [Array] array of steps to run
      # @return [Void]
      def run_commands steps
        steps.each do |step|
          if step[:env] == :remote
            if run_ssh_command step[:cmd]
              LOG.msg "#{step[:log]}", nil
            end
          else
            if system step[:cmd]
              LOG.msg "#{step[:log]}", nil
            end
          end
        end
      end

      # Get the path to releases directory
      # @return [String] the full release path
      def release_path
        File.join @project_root, @release_dir
      end

      # Get the path to the public directory
      # @return [String] the full public path
      def public_path
        File.join @project_root, @public_dir
      end

      # Get the path to the local directory to be synced
      # @return [String] the full local path
      def local_path
        File.join Dir.pwd, @local_dir
      end

      # The manifest location
      # @return [String] the manifest file path
      def manifest_path
        File.join @project_root, 'manifest.json'
      end

      # Get the manifest file contents
      # @return [Hash] the manifest data
      def get_manifest
        manifest = []
        command = "touch #{manifest_path} && tail -n 1000 #{manifest_path}"
        run_ssh_command(command) do |ch, stream, data|
          manifest = JSON.parse(data).sort_by { |r| r["time"] }.reverse
        end
        return manifest
      end

      # Add a release to the manifest
      # @param [String] release_name The release name
      # @return [Void]
      def add_manifest_release release_name
        releases = get_manifest || []
        releases << {
          name: "#{release_name}",
          time: Time.now.to_i,
          commit: Util.current_git_commit
        }
        run_ssh_command "echo '#{releases.to_json}' > #{manifest_path}"
      end

      # Remove a release from the manifest
      # @param [String] release_name The release name
      # @return [Void]
      def remove_manifest_release release_name
        releases = get_manifest
        releases.each_with_index do |release, idx|
          releases.delete_at(idx) if release['name'] == release_name
        end
        run_ssh_command "echo '#{releases.to_json}' > #{manifest_path}"
      end

      # Invoke the build task
      # @return [Rake::Task] the build rake task
      def build
        Rake::Task[@build_task]
      end

  end

end