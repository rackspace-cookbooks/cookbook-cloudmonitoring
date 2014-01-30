# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Provider:: alarm
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

include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  if @current_alarm.obj.nil?
    new_resource.updated_by_last_action(update_alarm(new_resource))
  else
    new_resource.updated_by_last_action(false)
  end
end

action :update do
  Chef::Log.debug("Beginning action[:update] for #{new_resource}")
  new_resource.updated_by_last_action(update_alarm(new_resource))
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  new_resource.updated_by_last_action(@current_alarm.delete)
end

def load_current_resource
  @current_alarm = CMAlarm.new(CMCredentials.new(node, new_resource), new_resource.entity_chef_label, new_resource.label)
  @current_alarm.lookup_by_label(new_resource.label)
end

def update_alarm(new_resource)
  criteria = new_resource.criteria
  check_id = new_resource.check_id

  if new_resource.example_id
    fail 'Cannot specify example_id and criteria' unless new_resource.criteria.nil?
    criteria = @current_alarm.example_alarm(new_resource.example_id, new_resource.example_values).bound_criteria
  end

  if new_resource.check_label
    fail 'Cannot specify check_label and check_id' unless new_resource.check_id.nil?

    check_obj = CMCheck.new(@current_alarm.credentials, new_resource.entity_chef_label, new_resource.check_label)
    check_obj.lookup_by_label(new_resource.check_label)

    if check_obj.obj.nil?
      fail "Unable to lookup check #{new_resource.check_label} on for alarm #{new_resource.label} on entity #{new_resource.entity_chef_label}"
    end

    check_id = check_obj.obj.id
  end

  if new_resource.notification_plan_id.nil?
    fail ValueError, 'Must specify notification_plan_id in alarm resource'
  end

  return @current_alarm.update(
    label:                new_resource.label,
    metadata:             new_resource.metadata,
    # Fog calls check_id check apparently?
    check:                check_id,
    criteria:             criteria,
    notification_plan_id: new_resource.notification_plan_id,
    disabled:             new_resource.disabled
  )
end
