# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Recipe:: default
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

# Required to install fog

if platform_family?('debian')
	node.override['apt']['compile_time_update'] = true
	include_recipe 'apt'
end

node.set['build-essential']['compile_time'] = true
include_recipe 'build-essential'

chef_gem 'nokogiri' do
  version '1.6.2.1'
end

include_recipe 'xml::ruby'

chef_gem 'fog' do
  version ">= #{node['rackspace_cloudmonitoring']['dependency_versions']['fog_version']}"
  action :install
end

# Load fog for the cloud_monitoring library
# https://sethvargo.com/using-gems-with-chef/
require 'fog'

# Mock out fog: THis code path is for testing
if node['rackspace_cloudmonitoring']['mock']
  Fog.mock!
end
