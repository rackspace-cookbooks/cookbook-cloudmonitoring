# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Provider:: agent_token
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

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  new_resource.updated_by_last_action(@current_agent_token.update(label: new_resource.label))
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  new_resource.updated_by_last_action(@current_agent_token.delete)
end

def load_current_resource
  @current_agent_token = CMAgentToken.new(CMCredentials.new(node, new_resource),
                                       new_resource.token,
                                       new_resource.label)
end
