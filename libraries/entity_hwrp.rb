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

require_relative 'CMEntity'
require_relative 'CMCredentials'
require 'chef/resource'
require 'ipaddr'

class Chef
  class Resource
    # Implement the rackspace_cloudmonitoring_agent_token resource
    class RackspaceCloudmonitoringEntity < Chef::Resource
      attr_accessor :entity_obj
      attr_writer   :entity_obj

      def initialize(name, run_context = nil)
        super
        @resource_name = :rackspace_cloudmonitoring_entity         # Bind ourselves to the name with an underscore
        @provider = Chef::Provider::RackspaceCloudmonitoringEntity # We need to tie to our provider
        @action = :create                                          # Default
        @allowed_actions = [:create, :create_if_missing, :delete, :nothing]

        @label = name
      end

      def label(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:label, arg, kind_of: String)
      end

      def api_label(arg = nil)
        set_or_return(:api_label, arg, kind_of: String)
      end

      def metadata(arg = nil)
        set_or_return(:metadata, arg, kind_of: Hash)
      end

      def ip_addresses(arg = nil)
        set_or_return(:ip_addresses, arg, kind_of: Hash)
      end

      def agent_id(arg = nil)
        set_or_return(:agent_id, arg, kind_of: String)
      end

      def search_method(arg = nil)
        set_or_return(:search_method, arg, kind_of: String)
      end

      def search_ip(arg = nil)
        set_or_return(:search_ip, arg, kind_of: String)
      end

      def search_id(arg = nil)
        set_or_return(:search_id, arg, kind_of: String)
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
    # Implement the rackspace_cloudmonitoring_agent_token provider
    class RackspaceCloudmonitoringEntity < Chef::Provider
      def load_current_resource
        # Here we keep the existing version of the resource
        # if none exists we create a new one from the resource we defined earlier
        @current_resource ||= Chef::Resource::RackspaceCloudmonitoringEntity.new(new_resource.name)

        [:label, :api_label, :metadata, :ip_addresses, :agent_id, :search_method, :search_ip,
         :search_id, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
          @current_resource.send(arg, new_resource.send(arg))
        end

        @current_resource.entity_obj = Opscode::Rackspace::Monitoring::CMEntity.new(
            Opscode::Rackspace::Monitoring::CMCredentials.new(node, new_resource),
            @current_resource.label
                                                                                    )

        case @current_resource.search_method
        when 'ip'
          if @current_resource.search_ip.nil?
            fail "Opscode::Rackspace::Monitoring::Entity #{@current_resource} load_current_resource: ERROR: ip search specified but search_ip nil"
          end
          @current_resource.entity_obj.lookup_entity_by_ip(@current_resource.search_ip)
        when 'id'
          if @current_resource.search_id.nil?
            fail "Opscode::Rackspace::Monitoring::Entity #{@current_resource} load_current_resource: ERROR: id search specified but search_id nil"
          end
          @current_resource.entity_obj.lookup_entity_by_id(@current_resource.search_id)
        when 'api_label'
          if @current_resource.api_label.nil?
            fail "Opscode::Rackspace::Monitoring::Entity #{@current_resource} load_current_resource: ERROR: api_label search specified but api_label nil"
          end
          @current_resource.entity_obj.lookup_entity_by_label(@current_resource.api_label)
        else
          @current_resource.entity_obj.lookup_entity_by_label(@current_resource.label)
        end

        @current_resource
      end

      def action_create
        Chef::Log.debug("Beginning action[:create] for #{@current_resource}")
        if @current_resource.entity_obj.entity_obj.nil?
          new_resource.updated_by_last_action(create_entity)
        else
          new_resource.updated_by_last_action(update_entity)
        end
      end

      def action_create_if_missing
        Chef::Log.debug("Beginning action[:create_if_missing] for #{@current_resource}")
        if @current_resource.entity_obj.entity_obj.nil?
          new_resource.updated_by_last_action(create_entity)
        else
          new_resource.updated_by_last_action(false)
        end
      end

      def action_delete
        Chef::Log.debug("Beginning action[:delete] for #{@current_resource}")
        new_resource.updated_by_last_action(@current_resource.entity_obj.delete_entity)
      end

      def action_nothing
        new_resource.updated_by_last_action(false)
      end
    end
  end
end

# create_entity: Create a new entity with all the things
def create_entity
  # normalize the ip's
  if @current_resource.ip_addresses
    new_ips = {}
    @current_resource.ip_addresses.each do |k, v|
      new_ips[k] = IPAddr.new(v).to_string
      Chef::Log.debug("Opscode::Rackspace::Monitoring::Entity #{@current_resource} create_entity: Adding IP #{k}: #{new_ips}")
    end
  else
    new_ips = nil
    if @current_resource.search_method == 'ip'
      fail "Opscode::Rackspace::Monitoring::Entity #{@current_resource} create ERROR: About to create an entity with no IPs when using ip search method.  Cowardly refusing to continue" # rubocop:disable LineLength
    end
  end

  return @current_resource.entity_obj.update_entity(
                                       label:        @current_resource.api_label ? @current_resource.api_label : @current_resource.label,
                                       ip_addresses: new_ips,
                                       metadata:     @current_resource.metadata,
                                       agent_id:     @current_resource.agent_id
                                       )
end

# update_entity: Only the following fields are updatable:
# metadata, agent_id
def update_entity
  return @current_resource.entity_obj.update_entity(
                                       metadata:     @current_resource.metadata,
                                       agent_id:     @current_resource.agent_id
                                       )
end
