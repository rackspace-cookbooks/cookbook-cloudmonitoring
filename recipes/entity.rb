#
# Cookbook Name:: cloud_monitoring
# Recipe:: entity
#
# Configure the cloud_monitoring_entity LWRP to use the existing entity
# for the node by matching the server IP.
#
# Copyright 2014, Rackspace
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

# cm is defined in libraries/cloud_monitoring.rb
class Chef::Recipe
  include Opscode::Rackspace::Monitoring
end

cm(defined?(node[:rackspace_cloudmonitoring]['rackspace_api_key']) ? node['cloud_monitoring']['rackspace_api_key'] : nil,
   defined?(node[:rackspace_cloudmonitoring]['rackspace_username']) ? node['cloud_monitoring']['rackspace_username'] : nil,
   defined?(node[:rackspace_cloudmonitoring]['rackspace_auth_url']) ? node['cloud_monitoring']['rackspace_auth_url'] : nil)

response = cm.list_entities.body


response["values"].each do |value|
  unless value["ip_addresses"].nil? || node["cloud"].nil?
    if value["ip_addresses"]["private0_v4"].eql? node["cloud"]["local_ipv4"]
      node.set[:rackspace_cloudmonitoring]['label'] = value["label"]
    end
  end
end

if node[:rackspace_cloudmonitoring]['label'].nil?
  node.set[:rackspace_cloudmonitoring]['label'] = node.hostname
end

cloud_monitoring_entity node[:rackspace_cloudmonitoring]['label'] do
  label                 node[:rackspace_cloudmonitoring]['label']
  agent_id              node[:rackspace_cloudmonitoring]['agent']['id']
  rackspace_username    node[:rackspace_cloudmonitoring]['rackspace_username']
  rackspace_api_key     node[:rackspace_cloudmonitoring]['rackspace_api_key']
  action :create                                 
end                                              
