module Statistrano
  module Util

    class FilePermissions

      attr_reader :user, :group, :others

      def initialize int
        @user, @group, @others = int.to_s.chars
      end

      def to_chmod
        Struct.new(:user, :group, :others)
              .new( chmod_map(user), chmod_map(group), chmod_map(others) )
      end

      private

        def chmod_map num
          {
            "7" => "rwx",
            "6" => "rw",
            "5" => "rx",
            "4" => "r",
            "3" => "wx",
            "2" => "w",
            "1" => "x",
            "0" => "-"
          }.fetch num
        end
    end

  end
end