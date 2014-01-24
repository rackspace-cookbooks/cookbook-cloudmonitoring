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
include_recipe 'rackspace_cloudmonitoring::default'
include_recipe 'rackspace_cloudmonitoring::agent'

rackspace_cloudmonitoring_entity node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label'] do
  agent_id      node['rackspace_cloudmonitoring']['config']['agent']['id']
  search_method 'ip'
  search_ip     node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_ip']
  action        :create
end

node['rackspace_cloudmonitoring']['monitors'].each do |check, check_value|
  rackspace_cloudmonitoring_check check do
    entity_chef_label node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']
    type              check_value['type']
    period            check_value.key?('period') ? check_value['period'] : node['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']
    timeout           check_value.key?('timeout') ? check_value['timeout'] : node['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout']
    details           check_value.key?('details') ? check_value['details'] : nil
    disabled          check_value.key?('disabled') ? check_value['details'] : false
    action            :create
  end

  if check_value.key?('alarm')
    check_value['alarm'].each do |alarm, alarm_value|
      # TODO: Add customizable messages, abstract the conditional more, etcetera...
      criteria = "if (#{alarm_value["conditional"]}) { return #{alarm}, '#{check} is past #{alarm} threshold' }"

      rackspace_cloudmonitoring_alarm  "#{check_value['type']} #{alarm} alarm" do
        entity_chef_label    node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']
        check_label          check
        criteria             criteria
        disabled             alarm_value.key?('disabled') ? alarm_value['details'] : false
        # Line length disabled on the next line as it is long due to long variable names, not complexity.
        notification_plan_id check_value.key?('notification_plan_id') ? check_value['notification_plan_id'] : node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] # rubocop:disable LineLength
        action               :create
      end

    end # alarm loop
  end # key?('alarm')
end # monitors loop
