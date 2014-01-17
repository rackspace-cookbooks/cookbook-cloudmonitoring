# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Provider:: entity
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

require 'ipaddr'

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  # normalize the ip's
  if new_resource.ip_addresses then
    new_ips = {}
    new_resource.ip_addresses.each {|k, v| new_ips[k] = IPAddr.new(v).to_string }
    new_resource.ip_addresses.update new_ips
  end
  
  new_resource.updated_by_last_action(@current_resource.update_entity(
    label:        new_resource.label,
    ip_addresses: new_resource.ip_addresses,
    metadata:     new_resource.metadata,
    agent_id:     new_resource.agent_id
  ))
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.delete_entity)
end


def load_current_resource
  @current_resource = CM_entity.new(CM_credentials.new(node, @new_resource), @new_resource.label)
  Chef::Log.debug("Opscode::Rackspace::Monitoring::Entity #{new_resource} load_current_resource: Using search method #{new_resource.search_method}")
  case new_resource.search_method
  when 'ip'
    @current_resource.lookup_entity_by_ip(@new_resource.search_ip)
  when 'id'
    @current_resource.lookup_entity_by_id(@new_resource.id)
  when 'api_label'
    @current_resource.lookup_entity_by_label(@new_resource.api_label)
  else
    @current_resource.lookup_entity_by_label(@new_resource.label)
  end
end
