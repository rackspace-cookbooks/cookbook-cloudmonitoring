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
# We use the shared node['rackspace']['cloud_credentials'] for the username and api key
# default['rackspace']['cloud_credentials']['username'] = nil
# default['rackspace']['cloud_credentials']['api_key'] = nil

# Default main configuration hash for monitors.rb
# No checks are defined by default as there is an account-wide limit and each check incurrs billing
# http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/api-rsource-limits.html
default['rackspace_cloudmonitoring']['monitors'] = {}

# Versions of dependency packages
default['rackspace_cloudmonitoring']['dependency_versions']['fog_version'] = '1.22.0'

# Credential Values
# default['rackspace_cloudmonitoring']['auth']['url'] = nil
default['rackspace_cloudmonitoring']['auth']['databag']['name'] = 'rackspace'
default['rackspace_cloudmonitoring']['auth']['databag']['item'] = 'cloud'

# Arguments passed into the agent config file
# default['rackspace_cloudmonitoring']['config']['agent']['token'] = nil
# default['rackspace_cloudmonitoring']['config']['agent']['id'] = nil
default['rackspace_cloudmonitoring']['config']['agent']['monitoring_endpoints'] = [] # This should be a list of strings like 'x.x.x.x:port'
                                                                                     # This is used in the agent configuratuon

default['rackspace_cloudmonitoring']['agent']['version'] = 'latest'
default['rackspace_cloudmonitoring']['agent']['plugin_path'] = '/usr/lib/rackspace-monitoring-agent/plugins'

# Plugins is a hash of [cookbook] = plugin_dir values
# The files in plugin_dir from the specified cookbook will be installed as plugins
default['rackspace_cloudmonitoring']['agent']['plugins'] = {}
# Add our plugin directory to the hash
default['rackspace_cloudmonitoring']['agent']['plugins']['rackspace_cloudmonitoring'] = 'plugins'

# Default values for monitors.rb
default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']         = node['hostname']
default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['ip_addresses']  = { default: node['ipaddress'] }

# Search by IP in Rackspace public cloud, search by label elsewhere
if node.key?('cloud')
  default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_method'] = node['cloud']['provider'] == 'rackspace' ? 'ip' : 'label'
else
  default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_method'] = 'label'
end

default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_ip']     = node['ipaddress']

default['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']         = 30
default['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout']        = 10
default['rackspace_cloudmonitoring']['monitors_defaults']['alarm']                           = {}
default['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['bypass_alarms']          = false # Skip alarm subhash and behave as if it didn't exist
# default['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = nil
default['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['consecutive_count']      = 2
default['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_old_alarms']      = true  # Remove alarms left from v2
default['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_orphan_alarms']   = true  # Remove alarms orphaned by alarm config hash block removal

# Configuration template overrides
default['rackspace_cloudmonitoring']['templates_cookbook']['rackspace-monitoring-agent'] = 'rackspace_cloudmonitoring'

# Testing option, not intended to be set in actual use
default['rackspace_cloudmonitoring']['mock'] = false

# Low level API tunable.  Sets the object count requested per API request.
# Exposed as a workaround until Fog issue 2908 is resolved.  Recommend removal once 2908 is resolved.
default['rackspace_cloudmonitoring']['api']['pagination_limit'] = 1000
