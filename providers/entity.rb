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
  Chef::Log.debug("Beginning action[:create] for #{@new_resource}")
  if @current_resource.entity_obj.nil?
    @new_resource.updated_by_last_action(create_entity)
  else
    @new_resource.updated_by_last_action(false)
  end
end

action :update do
  Chef::Log.debug("Beginning action[:update] for #{@new_resource}")
  if @current_resource.entity_obj.nil?
    @new_resource.updated_by_last_action(create_entity)
  else
    @new_resource.updated_by_last_action(update_entity)
  end
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{@new_resource}")
  @new_resource.updated_by_last_action(@current_resource.delete_entity)
end

def load_current_resource
  @current_resource = CMEntity.new(CMCredentials.new(node, @new_resource), @new_resource.label)
  Chef::Log.debug("Opscode::Rackspace::Monitoring::Entity #{@new_resource} load_current_resource: Using search method #{@new_resource.search_method}")
  case @new_resource.search_method
  when 'ip'
    fail "Opscode::Rackspace::Monitoring::Entity #{@new_resource} load_current_resource: ERROR: ip search specified but search_ip nil" if @new_resource.search_ip.nil?
    @current_resource.lookup_entity_by_ip(@new_resource.search_ip)
  when 'id'
    fail "Opscode::Rackspace::Monitoring::Entity #{@new_resource} load_current_resource: ERROR: id search specified but search_id nil" if @new_resource.search_id.nil?
    @current_resource.lookup_entity_by_id(@new_resource.search_id)
  when 'api_label'
    fail "Opscode::Rackspace::Monitoring::Entity #{@new_resource} load_current_resource: ERROR: api_label search specified but api_label nil" if @new_resource.api_label.nil?
    @current_resource.lookup_entity_by_label(@new_resource.api_label)
  else
    @current_resource.lookup_entity_by_label(@new_resource.label)
  end
end

# create_entity: Create a new entity with all the things
def create_entity
  # normalize the ip's
  if @new_resource.ip_addresses
    new_ips = {}
    @new_resource.ip_addresses.each { |k, v| new_ips[k] = IPAddr.new(v).to_string }
  else
    new_ips = nil
    if @new_resource.search_method == 'ip'
      fail "Opscode::Rackspace::Monitoring::Entity #{@new_resource} :create ERROR: About to create an entity with no IPs when using ip search method.  Cowardly refusing to continue" 
    end
  end
  
  return @current_resource.update_entity(
                                         label:        @new_resource.api_label ? @new_resource.api_label : @new_resource.label,
                                         ip_addresses: new_ips,
                                         metadata:     @new_resource.metadata,
                                         agent_id:     @new_resource.agent_id
                                         )
end

# update_entity: Only the following fields are updatable:
# metadata, agent_id
def update_entity
  return @current_resource.update_entity(
                                         metadata:     @new_resource.metadata,
                                         agent_id:     @new_resource.agent_id
                                         )
end
