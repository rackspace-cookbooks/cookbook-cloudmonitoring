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

node['cloud_monitoring']['monitors'].keys.sort.each do |key|
  cloud_monitoring_check key do
    type                  "agent.#{monitors[key]['type']}"
    period                monitors[key].has_key?('period') ? monitors[key]['period'] : node['cloud_monitoring']['check_default']['period']
    timeout               monitors[key].has_key?('timeout') ? monitors[key]['timeout'] : node['cloud_monitoring']['check_default']['timeout']
    rackspace_username    node['cloud_monitoring']['rackspace_username']
    rackspace_api_key     node['cloud_monitoring']['rackspace_api_key']
    retries               2
    details               monitors[key].has_key?('details') ? monitors[key]['details'] : nil
    action :create
  end
  
  if monitors[key].has_key?('alarm')
    monitors[key]["alarm"].keys.each do |alarm|
      # TODO: Add customizable messages, abstract the conditional more, etcetera...
      criteria = "if (#{monitors[key]["alarm"][alarm]["conditional"]}) { return #{alarm}, '#{key} is past #{alarm} threshold' }"
      
      cloud_monitoring_alarm  "#{monitors[key]['type']} #{alarm} alarm" do
        check_label           key
        criteria              criteria
        notification_plan_id  node['cloud_monitoring']['notification_plan_id']
        action                :create
      end

    end # monitors[key]["alarm"] loop
  end # if monitors[key].has_key?('alarm')
end # monitors.keys loop
