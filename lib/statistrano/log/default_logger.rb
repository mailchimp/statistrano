module Statistrano
  class Log


    # Error, Warning and Message Logging
    class DefaultLogger

      def info *msg
        status, msg = extract_status "", *msg

        case status
        when :success then
          color = :green
        else
          color = :bright
        end

        to_stdout status, color, *msg
      end
      alias_method :debug, :info

      def warn *msg
        status, msg = extract_status "warning", *msg
        to_stdout status, :yellow, *msg
      end

      def error *msg
        status, msg = extract_status "error", *msg
        to_stderr status, :red, *msg
      end
      alias_method :fatal, :error

      private

        def extract_status default, *msg
          if msg.first.is_a? Symbol
            status = msg.shift
          else
            status = default
          end
          [status, msg]
        end

        def to_stdout status, color, *msg
          $stdout.puts "#{Formatter.new(status, color, *msg).output}"
          $stdout.flush
        end

        def to_stderr status, color, *msg
          $stderr.puts "#{Formatter.new(status, color, *msg).output}"
          $stderr.flush
        end

      class Formatter
        attr_reader :width, :status, :color, :msgs

        def initialize status, color, *msg
          @width  = 14
          @status = status.to_s
          @color  = color
          @msgs   = msg
        end

        def output
          Rainbow(anchor).bright + padding + Rainbow(status).public_send(color) + formatted_messages
        end

        private

          def anchor
            "-> "
          end

          def padding
            num = (width - status.length)

            if num < 0
              @width = status.length + 1
              return spaces(0)
            else
              return spaces num
            end
          end

          def spaces num
            Array.new(num).join(" ")
          end

          def formatted_messages
            messages = []
            msgs.each_with_index do |msg, idx|
              if idx == 0
                messages << " #{msg}"
              else
                messages << "#{spaces( anchor.length + width )} #{msg}"
              end
            end
            messages.join("\n")
          end
      end

    end

  end
end
