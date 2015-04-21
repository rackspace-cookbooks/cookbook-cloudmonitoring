#
# Cookbook Name:: cloud_monitoring
# Recipe:: default
#
# Copyright 2012, Rackspace
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
include_recipe 'xml::ruby'

chef_gem 'fog' do
  version ">= #{node['cloud_monitoring']['fog_version']}"
  action :install
end

require 'fog'

begin
  # Access the Rackspace Cloud encrypted data_bag
  databag_dir = node['cloud_monitoring']['credentials']['databag_name']
  databag_filename = node['cloud_monitoring']['credentials']['databag_item']

  raxcloud = Chef::EncryptedDataBagItem.load(databag_dir, databag_filename)

  # Create variables for the Rackspace Cloud username and apikey
  node.default['cloud_monitoring']['rackspace_username'] = raxcloud['username']
  node.default['cloud_monitoring']['rackspace_api_key'] = raxcloud['apikey']
  node.default['cloud_monitoring']['rackspace_auth_region'] = raxcloud['region'] || 'notset'
  node.default['cloud_monitoring']['rackspace_auth_region'] = node['cloud_monitoring']['rackspace_auth_region'].downcase

  if node['cloud_monitoring']['rackspace_auth_region'] == 'us'
    node.default['cloud_monitoring']['rackspace_auth_url'] = 'https://identity.api.rackspacecloud.com/v2.0'
  elsif node['cloud_monitoring']['rackspace_auth_region'] == 'uk'
    node.default['cloud_monitoring']['rackspace_auth_url'] = 'https://lon.identity.api.rackspacecloud.com/v2.0'
  else
    Chef::Log.info "Using the encrypted data bag for rackspace cloud but no raxregion attribute was set (or it was set to something other then 'us' or 'uk'). Assuming 'us'. If you have a 'uk' account make sure to set the raxregion in your data bag"
    node.default['cloud_monitoring']['rackspace_auth_url'] = 'https://identity.api.rackspacecloud.com/v2.0'
  end

  %w(rackspace_username
     rackspace_api_key
  ).each do |var|
    if node['cloud_monitoring'][var].instance_variable_defined?('@current_normal')
      Chef::Log.warn "You have #{var} defined as a normal attribute. This means that it may be stored on your chef server (if you use one). The cookbook has been changed to set it as a default attribute, which will not automatically store on the chef server."
    end
  end
rescue Exception => e
  Chef::Log.error 'Failed to load rackspace cloud data bag: ' + e.to_s
end

if node[:cloud_monitoring][:rackspace_username] == 'your_rackspace_username' ||
   node['cloud_monitoring']['rackspace_api_key'] == 'your_rackspace_api_key'
  Chef::Log.info 'Rackspace username or api key has not been set. For this to work, either set the default attributes or create an encrypted databag of rackspace cloud per the cookbook README'
end
