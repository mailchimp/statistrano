require_relative 'remote/file'

module Statistrano

  # a remote is a databag of config specific for an
  # individual target for deployment
  # including it's own ssh connection to it's target server
  class Remote

    attr_reader :config

    def initialize config
      @config = config
      raise ArgumentError, "a hostname is required" unless config.hostname
    end

    def test_connection
      Log.info "testing connection to #{config.hostname}"

      resp = run 'whoami'
      done

      if resp.success?
        Log.info "#{config.hostname} says \"Hello #{resp.stdout.strip}\""
        return true
      else
        Log.error "connection failed for #{config.hostname}",
                  resp.stderr
        return false
      end
    end

    def run command
      if config.verbose
        Log.info :"#{config.hostname}", "running cmd: #{command}"
      end

      session.run command
    end

    def done
      session.close_session
    end

    def create_remote_dir path
      unless path[0] == "/"
        raise ArgumentError, "path must be absolute"
      end

      Log.info "Setting up directory at '#{path}' on #{config.hostname}"
      resp = run "mkdir -p -m #{config.dir_permissions} #{path}"
      unless resp.success?
        Log.error "Unable to create directory '#{path}' on #{config.hostname}",
                  resp.stderr
        abort()
      end
    end

    def rsync_to_remote local_path, remote_path
      local_path  = local_path.chomp("/")
      remote_path = remote_path.chomp("/")

      Log.info "Syncing files from '#{local_path}' to '#{remote_path}' on #{config.hostname}"

      time_before = Time.now
      resp = Shell.run_local "rsync #{rsync_options} " +
                             "-e ssh #{local_path}/ " +
                             "#{host_connection}:#{remote_path}/"
      time_after = Time.now
      total_time = (time_after - time_before).round(2)

      if resp.success?
        Log.info :success, "Files synced to remote on #{config.hostname} in #{total_time}s"
      else
        Log.error "Error syncing files to remote on #{config.hostname}",
                  resp.stderr
      end

      resp
    end

    private

      def session
        @_ssh_session ||= HereOrThere::Remote.session ssh_options
      end

      def ssh_options
        ssh_options = { hostname: config.hostname }
        [ :user, :password, :keys, :forward_agent ].each do |key|
          ssh_options[key] = config.public_send(key) if config.public_send(key)
        end

        return ssh_options
      end

      def host_connection
        config.user ? "#{config.user}@#{config.hostname}" : config.hostname
      end

      def rsync_options
        dir_perms  = Util::FilePermissions.new( config.dir_permissions ).to_chmod
        file_perms = Util::FilePermissions.new( config.file_permissions ).to_chmod

        "#{config.rsync_flags} --chmod=" +
            "Du=#{dir_perms.user},Dg=#{dir_perms.group},Do=#{dir_perms.others}," +
            "Fu=#{file_perms.user},Fg=#{file_perms.group},Fo=#{file_perms.others}"
      end

  end
end
