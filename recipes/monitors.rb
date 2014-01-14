#
# Cookbook Name:: cloud_monitoring
# Recipe:: monitors
#
# Configure checks and alarms for Rackspace MaaS
#
# Copyright 2014, Rackspace
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

# Include dependency recipes
include_recipe "cloud_monitoring"
include_recipe "cloud_monitoring::agent"
include_recipe "cloud_monitoring::entity"

node[:rackspace_cloudmonitoring]['monitors'].each do |key, value|
  cloud_monitoring_check key do
    type                  "agent.#{value['type']}"
    period                value.has_key?('period') ? value['period'] : node[:rackspace_cloudmonitoring]['check_default']['period']
    timeout               value.has_key?('timeout') ? value['timeout'] : node[:rackspace_cloudmonitoring]['check_default']['timeout']
    rackspace_username    node[:rackspace_cloudmonitoring]['rackspace_username']
    rackspace_api_key     node[:rackspace_cloudmonitoring]['rackspace_api_key']
    retries               2
    details               value.has_key?('details') ? value['details'] : nil
    action :create
  end
  
  if value.has_key?('alarm')
    value["alarm"].each do |alarm, alarm_value|
      # TODO: Add customizable messages, abstract the conditional more, etcetera...
      criteria = "if (#{alarm_value["conditional"]}) { return #{alarm}, '#{key} is past #{alarm} threshold' }"
      
      cloud_monitoring_alarm  "#{value['type']} #{alarm} alarm" do
        check_label           key
        criteria              criteria
        notification_plan_id  node[:rackspace_cloudmonitoring]['notification_plan_id']
        action                :create
      end

    end # alarm loop
  end # has_key?('alarm')
end # monitors loop
