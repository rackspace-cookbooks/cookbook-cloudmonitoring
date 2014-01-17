# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Recipe:: monitors
#
# Configure entity, checks and alarms for Rackspace MaaS
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

# Include dependency recipes
include_recipe 'rackspace_cloudmonitoring'
include_recipe 'rackspace_cloudmonitoring::agent'

rackspace_cloudmonitoring_entity node[:rackspace_cloudmonitoring][:monitors_defaults][:entity][:label] do
  agent_id              node[:rackspace_cloudmonitoring][:agent][:id]
  search_method         'ip'
  search_ip             node[:cloud][:local_ipv4]
  action :create                                 
end                                              

node[:rackspace_cloudmonitoring][:monitors].each do |key, value|
  rackspace_cloudmonitoring_check key do
    entity_chef_label     node[:rackspace_cloudmonitoring][:monitors_defaults][:entity][:label]
    type                  "agent.#{value['type']}"
    period                value.has_key?('period') ? value['period'] : node[:rackspace_cloudmonitoring][:monitors_defaults][:check][:period]
    timeout               value.has_key?('timeout') ? value['timeout'] : node[:rackspace_cloudmonitoring][:monitors_defaults][:check][:timeout]
    details               value.has_key?('details') ? value['details'] : nil
    action :create
  end
  
  if value.has_key?('alarm')
    value[:alarm].each do |alarm, alarm_value|
      # TODO: Add customizable messages, abstract the conditional more, etcetera...
      criteria = "if (#{alarm_value["conditional"]}) { return #{alarm}, '#{key} is past #{alarm} threshold' }"
      
      rackspace_cloudmonitoring_alarm  "#{value['type']} #{alarm} alarm" do
        entity_chef_label     node[:rackspace_cloudmonitoring][:monitors_defaults][:entity][:label]
        check_label           key
        criteria              criteria
        notification_plan_id  value.has_key?('notification_plan_id') ? value[:notification_plan_id] : node[:rackspace_cloudmonitoring][:monitors_defaults][:alarm][:notification_plan_id]
        action                :create
      end

    end # alarm loop
  end # has_key?('alarm')
end # monitors loop
