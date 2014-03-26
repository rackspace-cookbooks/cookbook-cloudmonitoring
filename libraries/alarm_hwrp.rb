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
# http://tech.yipit.com/2013/05/09/advanced-chef-writing-heavy-weight-resource-providers-hwrp/

require_relative 'CMAlarm'
require_relative 'CMCredentials'
require_relative 'CMCheck'
require 'chef/resource'

class Chef
  class Resource
    # Implement the rackspace_cloudmonitoring_alarm resource
    class RackspaceCloudmonitoringAlarm < Chef::Resource
      attr_accessor :alarm_obj
      attr_writer   :alarm_obj

      def initialize(name, run_context = nil)
        super
        @resource_name = :rackspace_cloudmonitoring_alarm         # Bind ourselves to the name with an underscore
        @provider = Chef::Provider::RackspaceCloudmonitoringAlarm # We need to tie to our provider
        @action = :create                                         # Default action
        @allowed_actions = [:create, :create_if_missing, :delete, :nothing]

        @label = name
      end

      def label(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:label, arg, kind_of: String)
      end

      def entity_chef_label(arg = nil)
        set_or_return(:entity_chef_label, arg, kind_of: String, required: true)
      end

      def notification_plan_id(arg = nil)
        set_or_return(:notification_plan_id, arg, kind_of: String)
      end

      def check_id(arg = nil)
        set_or_return(:check_id, arg, kind_of: String)
      end

      def check_label(arg = nil)
        set_or_return(:check_label, arg, kind_of: String)
      end

      def metadata(arg = nil)
        set_or_return(:metadata, arg, kind_of: Hash)
      end

      def criteria(arg = nil)
        set_or_return(:criteria, arg, kind_of: String)
      end

      def disabled(arg = nil)
        set_or_return(:disabled, arg, kind_of: [TrueClass, FalseClass])
      end

      def example_id(arg = nil)
        set_or_return(:example_id, arg, kind_of: String)
      end

      def example_values(arg = nil)
        set_or_return(:example_values, arg, kind_of: Hash)
      end

      def rackspace_api_key(arg = nil)
        set_or_return(:rackspace_api_key, arg, kind_of: String)
      end

      def rackspace_username(arg = nil)
        set_or_return(:rackspace_username, arg, kind_of: String)
      end

      def rackspace_auth_url(arg = nil)
        set_or_return(:rackspace_auth_url, arg, kind_of: String)
      end
    end
  end
end

class Chef
  class Provider
    # Implement the rackspace_cloudmonitoring_alarm provider
    class RackspaceCloudmonitoringAlarm < Chef::Provider
      def load_current_resource
        # Here we keep the existing version of the resource
        # if none exists we create a new one from the resource we defined earlier
        @current_resource ||= Chef::Resource::RackspaceCloudmonitoringAlarm.new(new_resource.name)
        [:label, :entity_chef_label, :notification_plan_id, :check_id, :check_label, :metadata, :criteria, :disabled, :example_id,
         :example_values, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
          @current_resource.send(arg, new_resource.send(arg))
        end

        @current_resource.alarm_obj = Opscode::Rackspace::Monitoring::CMAlarm.new(
              Opscode::Rackspace::Monitoring::CMCredentials.new(node, @current_resource),
              @current_resource.entity_chef_label, @current_resource.label)
        @current_resource.alarm_obj.lookup_by_label(@current_resource.label)

        @current_resource
      end

      def action_create
        Chef::Log.debug("Beginning action[:create] for #{@current_resource}")
        new_resource.updated_by_last_action(update_alarm(@current_resource))
      end

      def action_create_if_missing
        Chef::Log.debug("Beginning action[:create_if_missing] for #{@current_resource}")
        if @current_resource.alarm_obj.obj.nil?
          new_resource.updated_by_last_action(update_alarm(@current_resource))
        else
          new_resource.updated_by_last_action(false)
        end
      end

      def action_delete
        Chef::Log.debug("Beginning action[:delete] for #{@current_resource}")
        new_resource.updated_by_last_action(@current_resource.alarm_obj.delete)
      end

      def action_nothing
        new_resource.updated_by_last_action(false)
      end

      # update_alarm: internal helper shared by the create* actions
      def update_alarm(resource)
        fail 'notification_plan_id is required' if resource.notification_plan_id.nil?

        if resource.example_id
          fail 'Cannot specify example_id and criteria' unless resource.criteria.nil?
          criteria =  resource.alarm_obj.example_alarm(resource.example_id, resource.example_values).bound_criteria
        else
          criteria = resource.criteria
        end

        if resource.check_label
          fail 'Cannot specify check_label and check_id' unless resource.check_id.nil?

          check_obj = Opscode::Rackspace::Monitoring::CMCheck.new(resource.alarm_obj.credentials, resource.entity_chef_label, resource.check_label)
          check_obj.lookup_by_label(resource.check_label)

          if check_obj.obj.nil?
            fail "Unable to lookup check #{resource.check_label} on for alarm #{resource.label} on entity #{resource.entity_chef_label}"
          end

          check_id = check_obj.obj.id
        else
          check_id = resource.check_id
        end

        if resource.notification_plan_id.nil?
          fail ValueError, 'Must specify notification_plan_id in alarm resource'
        end

        return resource.alarm_obj.update(
                                         label:                resource.label,
                                         metadata:             resource.metadata,
                                         # Fog calls check_id check apparently?
                                         check:                check_id,
                                         criteria:             criteria,
                                         notification_plan_id: resource.notification_plan_id,
                                         disabled:             resource.disabled
                                         )
      end
    end
  end
end
