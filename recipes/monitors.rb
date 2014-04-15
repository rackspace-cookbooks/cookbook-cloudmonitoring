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

# Include our helpers
class Chef::Recipe
  include Opscode::Rackspace::Monitoring::MonitorsRecipeHelpers
end

rackspace_cloudmonitoring_entity node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label'] do
  agent_id      node['rackspace_cloudmonitoring']['config']['agent']['id']
  search_method node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_method']
  search_ip     node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_ip']
  ip_addresses  node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['ip_addresses']
  action        :create
end

node['rackspace_cloudmonitoring']['monitors'].each do |check, check_value|
  rackspace_cloudmonitoring_check check do
    entity_chef_label node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']
    type              check_value['type']
    period            check_value.key?('period') ? check_value['period'] : node['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']
    timeout           check_value.key?('timeout') ? check_value['timeout'] : node['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout']
    details           check_value.key?('details') ? check_value['details'] : nil
    disabled          check_value.key?('disabled') ? check_value['disabled'] : false
    metadata          check_value.key?('metadata') ? check_value['metadata'] : nil
    target_alias      check_value.key?('target_alias') ? check_value['target_alias'] : nil
    target_hostname   check_value.key?('target_hostname') ? check_value['target_hostname'] : nil
    target_resolver   check_value.key?('target_resolver') ? check_value['target_resolver'] : nil
    monitoring_zones_poll check_value.key?('monitoring_zones_poll') ? check_value['monitoring_zones_poll'] : nil

    action            :create
  end

  if check_value.key?('alarm') && node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['bypass_alarms'] == false
    if check_value['alarm'].key?('consecutive_count')
      consecutive_count = check_value['alarm']['consecutive_count']
    else
      consecutive_count = node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['consecutive_count']
    end

    alarm_criteria = ":set consecutiveCount=#{consecutive_count}\n"
    states_specified = false

    # CRITICAL and WARNING are helpers for the state array
    %w(CRITICAL WARNING).each do |state|
      if check_value['alarm'].key?(state)
        alarm_criteria << generate_alarm_dsl_block(check_value['alarm'][state], check, state)
        states_specified = true
      end
    end

    if check_value['alarm'].key?('states')
      check_value['alarm']['states'].each do |state_data|
        alarm_criteria << generate_alarm_dsl_block(state_data, check)
        states_specified = true
      end
    end

    if check_value['alarm']['alarm_dsl'].nil?
      # Fail if no states were specified
      # Don't fail if alarm_criteria == "" as we may have disabled states and we want the alarm to go OK.
      # (Hence the boolean flag)
      fail "ERROR: Check #{check}: has no states!" if states_specified == false

      # Add OK block
      if check_value['alarm']['ok_message'].nil?
        ok_message = "#{check} is clear"
      else
        ok_message = check_value['alarm']['ok_message']
      end

      alarm_criteria << "return new AlarmStatus(OK, '#{ok_message}');"
    else
      # We're testing for alarm_dsl here as it allows an easy check to see if we have exclusive options
      # if states_specified == true then options have been set which will be overridden possibly resulting
      #   in unexpected bahavior
      fail "ERROR: Check #{check}: alarm_dsl was specified along with individual state declarations" unless states_specified == false
      fail 'ERROR: ok_message and alarm_dsl are exclusive.' unless check_value['alarm']['ok_message'].nil?

      alarm_criteria = check_value['alarm']['alarm_dsl']
    end

    if check_value['alarm']['notification_plan_id'].nil?
      notification_plan = node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id']
    else
      notification_plan = check_value['alarm']['notification_plan_id']
    end

    rackspace_cloudmonitoring_alarm "#{check} alarm" do
      entity_chef_label    node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']
      check_label          check
      criteria             alarm_criteria
      disabled             check_value['alarm']['disabled'].nil? ? false : check_value['alarm']['disabled']
      metadata             check_value['alarm']['metadata'].nil? ? nil : check_value['alarm']['metadata']
      notification_plan_id notification_plan
      action               :create
    end

    if check_value['alarm']['remove_old_alarms'].nil?
      remove_alarms = node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_old_alarms']
    else
      remove_alarms = check_value['alarm']['remove_old_alarms']
    end

    # Clean up behind old versions
    if remove_alarms
      %w(CRITICAL WARNING).each do |alarm|
        rackspace_cloudmonitoring_alarm  "#{check} #{alarm} alarm" do
          entity_chef_label    node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']
          action :delete
        end
      end
    end
  else
    if node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_orphan_alarms']
      # Alarms unset: As we know the name of any orphaned alarms go ahead and remove them
      rackspace_cloudmonitoring_alarm "#{check} alarm" do
        entity_chef_label    node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']
        action :delete
      end
    end
  end # key?('alarm')
end # monitors loop
