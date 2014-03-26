# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Library:: cloud_monitoring
#
# Copyright 2014, Rackspace, US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Opscode
  module Rackspace
    module Monitoring
      # MonitorsRecipeHelpers: Helper functions for the monitors recipe
      module MonitorsRecipeHelpers
        # generate_alarm_dsl_block: Generate a if() return block of alarm DSL for a given check
        def generate_alarm_dsl_block(alarm_data_hash, check, default_state = nil)
          # Generate state
          if alarm_data_hash['state'].nil?
            if default_state.nil?
              fail "ERROR: #{check}: Alarm with missing state detected"
            else
              state = default_state
            end
          else
            state = alarm_data_hash['state']
          end

          # Check for deprecated options
          %w(alarm_dsl metadata notification_plan_id).each do |deprecated_option|
            if alarm_data_hash.key?(deprecated_option)
              fail "ERROR: #{check} #{state} state alarm: #{deprecated_option} option within a specific alarm state is now deprecated.  See cookbook documentation."
            end
          end

          if alarm_data_hash.key?('disabled')
            if alarm_data_hash['disabled']
              # Return nothing if it is disabled.
              return ''
            end
          end

          fail "ERROR: #{check} #{state} state alarm: Mandatory alarm argument conditional unset" if alarm_data_hash['conditional'].nil?

          if alarm_data_hash['message'].nil?
            message = "#{check} is past #{state} threshold"
          else
            message = alarm_data_hash['message']
          end

          return "if (#{alarm_data_hash["conditional"]}) { return new AlarmStatus(#{state}, '#{message}'); }\n"
        end
        module_function :generate_alarm_dsl_block
      end
    end
  end
end
