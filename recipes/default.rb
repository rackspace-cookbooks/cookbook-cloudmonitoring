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

case node['platform']
when "ubuntu","debian"
  package( "libxslt-dev" ).run_action( :install )
  package( "libxml2-dev" ).run_action( :install )
when "redhat","centos","fedora", "amazon","scientific"
  package( "libxslt-devel" ).run_action( :install )
  package( "libxml2-devel" ).run_action( :install )
end

r = gem_package "rackspace-monitoring" do
  version node['cloud_monitoring']['version']
  action :nothing
end

r.run_action(:install)

require 'rubygems'
Gem.clear_paths
require 'rackspace-monitoring'

if Chef::DataBag.list.keys.include?("rackspace") && data_bag("rackspace").include?("cloud")
  #Access the Rackspace Cloud encrypted data_bag
  raxcloud = Chef::EncryptedDataBagItem.load("rackspace","cloud")

  #Create variables for the Rackspace Cloud username and apikey
  node['cloud_monitoring']['rackspace_username'] = raxcloud['raxusername']
  node['cloud_monitoring']['rackspace_api_key'] = raxcloud['raxapikey']
  node['cloud_monitoring']['raxregion'] = raxcloud['raxregion'] || 'us'
  node['cloud_monitoring']['raxregion'] = node['cloud_monitoring']['raxregion'].downcase

  if node['cloud_monitoring']['raxregion'] == 'us'
    node['cloud_monitoring']['rackspace_auth_url'] = 'https://identity.api.rackspacecloud.com/v2.0'
  elsif   node['cloud_monitoring']['raxregion']  == 'uk'
    node['cloud_monitoring']['rackspace_auth_url'] = 'https://lon.identity.api.rackspacecloud.com/v2.0'
  else
    node['cloud_monitoring']['rackspace_auth_url'] = 'https://identity.api.rackspacecloud.com/v2.0'
  end
end
