# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Attributes:: default
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

# (Optional)
# We use the shared node[:rackspace][:cloud_credentials] for the username and api key
#default[:rackspace][:cloud_credentials][:username] = nil
#default[:rackspace][:cloud_credentials][:api_key] = nil

# Default main configuration hash for monitors.rb
# No checks are defined by default as there is an account-wide limit and each check incurrs billing
# http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/api-rsource-limits.html
default[:rackspace_cloudmonitoring][:monitors] = {}

# TODO: Add :config namespace for config file

# Versions of dependency packages
# TODO: Verify revisions
# TODO: Look into forking fog cookbook
default[:rackspace_cloudmonitoring][:dependency_versions][:rackspace_monitoring_version] = '0.2.18'
default[:rackspace_cloudmonitoring][:dependency_versions][:fog_version] = '1.16.0' # 1.19

# Credential Values
#default[:rackspace_cloudmonitoring][:auth][:url] = nil
default[:rackspace_cloudmonitoring][:auth][:databag][:name] = 'rackspace'
default[:rackspace_cloudmonitoring][:auth][:databag][:item] = 'cloud'

default[:rackspace_cloudmonitoring][:agent][:version] = 'latest'
#default[:rackspace_cloudmonitoring][:agent][:token] = nil
default[:rackspace_cloudmonitoring][:agent][:monitoring_endpoints] = [] # This should be a list of strings like 'x.x.x.x:port'
                                                                        # This is used in the agent configuratuon
                                                                        # TODO: See if this can be populated from Fog

default[:rackspace_cloudmonitoring][:agent][:plugin_path] = '/usr/lib/rackspace-monitoring-agent/plugins'

# Plugins is a hash of [cookbook] = plugin_dir values
# The files in plugin_dir from the specified cookbook will be installed as plugins
default[:rackspace_cloudmonitoring][:agent][:plugins] = {}
# Add our plugin directory to the hash
default[:rackspace_cloudmonitoring][:agent][:plugins][:rackspace_cloudmonitoring] = 'plugins'

# Check values
default[:rackspace_cloudmonitoring][:monitors_defaults][:entity][:label] = node.hostname
default[:rackspace_cloudmonitoring][:monitors_defaults][:check][:period] = 30
default[:rackspace_cloudmonitoring][:monitors_defaults][:check][:timeout] = 10
#node[:rackspace_cloudmonitoring][:monitors_defaults][:alarm][:notification_plan_id] = nil


# Configuration template overrides
default[:rackspace_cloudmonitoring][:templates_cookbook][:'rackspace-monitoring-agent'] = 'rackspace_cloudmonitoring'
default[:rackspace_cloudmonitoring][:templates_cookbook][:raxrc]                        = 'rackspace_cloudmonitoring'
