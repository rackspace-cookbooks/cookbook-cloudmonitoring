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

require_relative 'CMChild.rb'

module Opscode
  module Rackspace
    module Monitoring
      # CMAlarm: Class for handling Cloud Monitoring Alarm objects
      class CMAlarm < Opscode::Rackspace::Monitoring::CMChild
        # Note that this initializer DOES NOT LOAD ANY ALARMS!
        # User must call a lookup function before calling update
        def initialize(credentials, entity_label, my_label)
          super(credentials, entity_label, 'alarms', 'Alarm', my_label)
          @credentials = credentials
        end

        # get_credentials: return the credentials used
        # PRE: None
        # POST: None
        # RETURN VALUE: CMCredentials class
        # This is a *bit* of a hack as @credentials was originially saved in case get_example_alarm was called
        # which needs a cm object and should otherwise not be needed.  However, it makes our life slightly easier
        # in the alarm LWRP as we can use it to pass to the CMCheck constructor to get the check ID.
        def credentials
          return @credentials
        end

        # example_alarm: Look up an alarm definition from the example API and return its criteria
        # This does not modify the current alarm object, but it does require the inherited CMApi class
        # PRE: None
        # POST: None
        # Return Value: bound_criteria string
        def example_alarm(example_id, example_values)
          @cm = CMApi.new(@credentials).cm
          return @cm.alarm_examples.evaluate(example_id, example_values).bound_criteria
        end
      end
    end # END MODULE
  end
end
