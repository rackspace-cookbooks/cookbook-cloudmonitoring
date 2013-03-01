
begin
  require "docile"
rescue LoadError
  Chef::Log.warn("Missing gem 'docile'")
end

module Rackspace
  module CloudMonitoring
    class MonitoringCriteria
      attr_accessor :alerts
      def initialize
        @alerts = []
      end
      def warn_if(*args)
        alert_if("WARNING", args)
      end
      def critical_if(*args)
        alert_if("CRITICAL", args)
      end
      def ok(msg)
        @alerts << return_message("OK", msg)
      end
      def to_s
        @alerts.join("\n")
      end

      private
      def alert_if(level, args)
        @alerts << create(
          args[0],
          args[1],
          args[2],
          return_message(level, args[3])
          )
      end
      def return_message(level, msg)
        "return new AlarmStatus(#{level}, '#{msg}');"
      end
      def create(left_value, test_method, right_value, return_status)
        test_methods = [">", "<", ">=", "<=", "==", "!="]
        unless test_methods.include?(test_method)
          raise "comparator must be one of #{test_methods.join(", ")}"
        end
        msg = "if (#{left_value} #{test_method} #{right_value}) {\n\t"
        msg += return_status
        msg += "\n}"
        msg
      end
      def percentage(first, second)
        "percentage(metric['#{first}'], metric['#{second}'])"
      end
      def metric(name)
        "metric['#{name}']"
      end
    end
  end
end
