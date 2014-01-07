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
include_recipe "cloud_monitoring::entity"

node['cloud_monitoring']['monitors'].each do |key, value|
  cloud_monitoring_check key do
    type                  "agent.#{value['type']}"
    period                monitors[key].has_key?('period') ? value['period'] : node['cloud_monitoring']['check_default']['period']
    timeout               monitors[key].has_key?('timeout') ? value['timeout'] : node['cloud_monitoring']['check_default']['timeout']
    rackspace_username    node['cloud_monitoring']['rackspace_username']
    rackspace_api_key     node['cloud_monitoring']['rackspace_api_key']
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
        notification_plan_id  node['cloud_monitoring']['notification_plan_id']
        action                :create
      end

    end # alarm loop
  end # has_key?('alarm')
end # monitors loop
