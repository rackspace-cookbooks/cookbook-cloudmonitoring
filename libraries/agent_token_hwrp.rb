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

require_relative 'CMAgentToken'
require_relative 'CMCredentials'
require 'chef/resource'

class Chef
  class Resource
    # Implement the rackspace_cloudmonitoring_agent_token resource
    class RackspaceCloudmonitoringAgentToken < Chef::Resource
      attr_accessor :token_obj
      attr_writer   :token_obj

      def initialize(name, run_context = nil)
        super
        @resource_name = :rackspace_cloudmonitoring_agent_token        # Bind ourselves to the name with an underscore
        @provider = Chef::Provider::RackspaceCloudmonitoringAgentToken # We need to tie to our provider
        @action = :create                                              # Default
        @allowed_actions = [:create, :create_if_missing, :delete, :nothing]

        @label = name
      end

      def label(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:label, arg, kind_of: String)
      end

      def token(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:token, arg, kind_of: String)
      end

      def rackspace_api_key(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:rackspace_api_key, arg, kind_of: String)
      end

      def rackspace_username(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:rackspace_username, arg, kind_of: String)
      end

      def rackspace_auth_url(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:rackspace_auth_url, arg, kind_of: String)
      end
    end
  end
end

class Chef
  class Provider
    # Implement the rackspace_cloudmonitoring_agent_token provider
    class RackspaceCloudmonitoringAgentToken < Chef::Provider
      def load_current_resource
        # Here we keep the existing version of the resource
        # if none exists we create a new one from the resource we defined earlier
        @current_resource ||= Chef::Resource::RackspaceCloudmonitoringAgentToken.new(new_resource.name)

        @current_resource.label(new_resource.label)
        @current_resource.token(new_resource.token)
        @current_resource.rackspace_api_key(new_resource.rackspace_api_key)
        @current_resource.rackspace_username(new_resource.rackspace_username)
        @current_resource.rackspace_auth_url(new_resource.rackspace_auth_url)

        @current_resource.token_obj = Opscode::Rackspace::Monitoring::CMAgentToken.new(
            Opscode::Rackspace::Monitoring::CMCredentials.new(node, new_resource),
            @current_resource.token,
            @current_resource.label)

        @current_resource
      end

      def action_create
        Chef::Log.debug("Beginning action[:create] for #{@current_resource}")
        new_resource.updated_by_last_action(@current_resource.token_obj.update(label: @current_resource.label))
      end

      def action_create_if_missing
        Chef::Log.debug("Beginning action[:create_if_missing] for #{@current_resource}")
        if @current_resource.token_obj.obj.nil?
          new_resource.updated_by_last_action(@current_resource.token_obj.update(label: @current_resource.label))
        else
          new_resource.updated_by_last_action(false)
        end
      end

      def action_delete
        Chef::Log.debug("Beginning action[:delete] for #{@current_resource}")
        new_resource.updated_by_last_action(@current_resource.token_obj.delete)
      end

      def action_nothing
        new_resource.updated_by_last_action(false)
      end
    end
  end
end
