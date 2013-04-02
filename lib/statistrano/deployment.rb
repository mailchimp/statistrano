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
      end

      def initialize name
        @name = name
        @config = Config.new
        yield(@config) if block_given?
      end
    end


  end
end