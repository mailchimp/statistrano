module Statistrano
  module Deployment

    class Releases < Base

      class Config < Base::Config
        attr_accessor :release_count
        attr_accessor :release_dir
        attr_accessor :public_dir
        attr_accessor :git_branch
      end

      def initialize name
      end

    end

  end
end