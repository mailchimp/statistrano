module Statistrano
  module Deployment
    class MultiTarget

      class Target
        extend ::Statistrano::Config::Configurable

        options :remote_dir, :local_dir,
                :remote, :user, :password, :keys, :forward_agent

        option :release_count, 5
        option :release_dir, "releases"
        option :public_dir,  "current"
      end

    end
  end
end