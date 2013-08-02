module Statistrano
  module ConfigAttribute
    NO_ARGUMENT = Object.new

    def config_attribute *args
      args.each do |arg|
        self.class_eval ("
          attr_writer :#{arg}
          def #{arg} val=NO_ARGUMENT
            if val == NO_ARGUMENT
              @#{arg}
            else
              @#{arg} = val
            end
          end
          ")
      end
    end
  end
end