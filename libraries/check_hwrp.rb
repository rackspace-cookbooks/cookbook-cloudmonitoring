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

require_relative 'CMCheck'
require_relative 'CMCredentials'
require 'chef/resource'

class Chef
  class Resource
    # Implement the rackspace_cloudmonitoring_check resource
    class RackspaceCloudmonitoringCheck < Chef::Resource
      attr_accessor :check_obj
      attr_writer   :check_obj

      def initialize(name, run_context = nil)
        super
        @resource_name = :rackspace_cloudmonitoring_check         # Bind ourselves to the name with an underscore
        @provider = Chef::Provider::RackspaceCloudmonitoringCheck # We need to tie to our provider
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

      def type(arg = nil)
        set_or_return(:type, arg, kind_of: String, required: true)
      end

      def details(arg = nil)
        set_or_return(:details, arg, kind_of: Hash)
      end

      def metadata(arg = nil)
        set_or_return(:metadata, arg, kind_of: Hash)
      end

      def period(arg = nil)
        set_or_return(:period, arg, kind_of: Integer)
      end

      def timeout(arg = nil)
        set_or_return(:timeout, arg, kind_of: Integer)
      end

      def disabled(arg = nil)
        set_or_return(:disabled, arg, kind_of: [TrueClass, FalseClass])
      end

      def target_alias(arg = nil)
        set_or_return(:target_alias, arg, kind_of: String)
      end

      def target_resolver(arg = nil)
        set_or_return(:target_resolver, arg, kind_of: String)
      end

      def target_hostname(arg = nil)
        set_or_return(:target_hostname, arg, kind_of: String)
      end

      def monitoring_zones_poll(arg = nil)
        set_or_return(:monitoring_zones_poll, arg, kind_of: Array)
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
    # Implement the rackspace_cloudmonitoring_check provider
    class RackspaceCloudmonitoringCheck < Chef::Provider
      def load_current_resource
        # Here we keep the existing version of the resource
        # if none exists we create a new one from the resource we defined earlier
        @current_resource ||= Chef::Resource::RackspaceCloudmonitoringCheck.new(new_resource.name)
        [:label, :entity_chef_label, :type, :details, :metadata, :period, :timeout, :disabled, :target_alias, :target_resolver,
         :target_hostname, :monitoring_zones_poll, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
          @current_resource.send(arg, new_resource.send(arg))
        end

        @current_resource.check_obj = Opscode::Rackspace::Monitoring::CMCheck.new(
              Opscode::Rackspace::Monitoring::CMCredentials.new(node, @current_resource),
              @current_resource.entity_chef_label, @current_resource.label)
        @current_resource.check_obj.lookup_by_label(@current_resource.label)

        @current_resource
      end

      def action_create
        Chef::Log.debug("Beginning action[:create] for #{@current_resource}")
        new_resource.updated_by_last_action(@current_resource.check_obj.update(
                                                                  label:                 @current_resource.label,
                                                                  type:                  @current_resource.type,
                                                                  details:               @current_resource.details,
                                                                  metadata:              @current_resource.metadata,
                                                                  monitoring_zones_poll: @current_resource.monitoring_zones_poll,
                                                                  target_alias:          @current_resource.target_alias,
                                                                  target_hostname:       @current_resource.target_hostname,
                                                                  target_resolver:       @current_resource.target_resolver,
                                                                  timeout:               @current_resource.timeout,
                                                                  period:                @current_resource.period,
                                                                  disabled:              @current_resource.disabled
                                                                  ))
      end

      def action_create_if_missing
        Chef::Log.debug("Beginning action[:create_if_missing] for #{@current_resource}")
        if @current_resource.check_obj.obj.nil?
          new_resource.updated_by_last_action(@current_resource.check_obj.update(
                                                                                 label:                 @current_resource.label,
                                                                                 type:                  @current_resource.type,
                                                                                 details:               @current_resource.details,
                                                                                 metadata:              @current_resource.metadata,
                                                                                 monitoring_zones_poll: @current_resource.monitoring_zones_poll,
                                                                                 target_alias:          @current_resource.target_alias,
                                                                                 target_hostname:       @current_resource.target_hostname,
                                                                                 target_resolver:       @current_resource.target_resolver,
                                                                                 timeout:               @current_resource.timeout,
                                                                                 period:                @current_resource.period,
                                                                                 disabled:              @current_resource.disabled
                                                                                 ))
        else
          new_resource.updated_by_last_action(false)
        end
      end

      def action_delete
        Chef::Log.debug("Beginning action[:delete] for #{@current_resource}")
        new_resource.updated_by_last_action(@current_resource.check_obj.delete)
      end

      def action_nothing
        new_resource.updated_by_last_action(false)
      end
    end
  end
end
