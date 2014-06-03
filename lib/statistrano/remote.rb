require_relative "remote/file"

module Statistrano

  # a remote is a databag of config specific for an
  # individual target for deployment
  # including it's own ssh connection to it's target server
  class Remote
    extend ::Statistrano::Config::Configurable
    options :hostname, :user, :password, :keys, :forward_agent

    # included to allow override in Releaser,
    # generally these should not be used
    options :remote_dir, :local_dir,
            :release_count, :release_dir, :public_dir

    # configure rsync & setup operations
    option :dir_permissions,  755
    option :file_permissions, 644
    option :rsync_flags,      '-aqz --delete-after'


    option  :verbose, false

    def initialize options={}
      config.options.each do |opt,val|
        config.send opt, (options.fetch(opt,val) || val)
      end

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

    def deployment_active? remote_dir
      status = deployment_status_file(remote_dir).content
      unless status.empty?
        Log.info "#{status} is currently deploying"
        return status
      else
        return false
      end
    end
    # false || `whoami`

    def set_deployment_active remote_dir
      current_user = Shell.run_local("whoami").stdout
      active_dep   = deployment_active?(remote_dir)

      if active_dep && active_dep != current_user
        Log.error "can't set deployment to active"
        abort()
      else
        deployment_status_file(remote_dir).update_content! current_user
      end
    end

    def set_deployment_inactive remote_dir
      current_user = Shell.run_local "whoami"
      active_dep   = deployment_active?(remote_dir)

      if active_dep && active_dep != current_user
        Log.error "can't set deployment to inactive",
                  "#{active_dep} is currently deploying"
        abort()
      else
        deployment_status_file(remote_dir).destroy!
      end
    end

    private

      def deployment_status_file remote_dir
        Remote::File.new( ::File.join(remote_dir, '.deployment_status'),
                          self,
                          config.file_permissions )
      end

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