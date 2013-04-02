module Statistrano
  module Deployment

    # A Base Deployment Instance
    class Base

      attr_reader :name
      attr_reader :config

      class Config
        attr_accessor :remote_dir
        attr_accessor :local_dir
        attr_accessor :remote
        attr_accessor :build_task
        attr_accessor :check_git
        attr_accessor :post_deploy_task
      end

      def initialize name
        @name = name
        @config = Config.new
      end
    end


  end
end