#
# Cookbook Name:: rackspace_cloudmonitoring
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

require 'spec_helper'

describe 'rackspace_cloudmonitoring::agent' do
  rackspace_cloudmonitoring_test_platforms.each do |platform, versions|
    describe "on #{platform}" do
      versions.each do |version|
        describe version do
          let(:chef_run) do
            ChefSpec::Runner.new(platform: platform.to_s,
                                 version: version.to_s,
                                 step_into: ['rackspace_cloudmonitoring_agent_token']
                                 ) do |node|
              node.set['rackspace_cloudmonitoring']['mock'] = true
            end
          end

          describe 'with explicit token and ID' do
            before :each do
              chef_run.node.set['rackspace_cloudmonitoring']['config']['agent']['id']    = 'rackspacerules'
              chef_run.node.set['rackspace_cloudmonitoring']['config']['agent']['token'] = 'kittenmittens'
              chef_run.converge('rackspace_cloudmonitoring::agent')
            end

            it 'include the default recipe' do
              expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::default'
            end

            it 'create the config tile' do
              expect(chef_run).to create_template '/etc/rackspace-monitoring-agent.cfg'
            end

            #
            # Current no check for the repo, I don't see any repostitory machers in https://github.com/sethvargo/chefspec/tree/master/lib/chefspec/api
            # Test kitchen will catch that, though.
            #

            it 'install the monitoring agent pinned to a version' do
              chef_run.node.set['rackspace_cloudmonitoring']['agent']['version'] = '1.2.3'
              chef_run.converge('rackspace_cloudmonitoring::agent')
              expect(chef_run).to install_package 'rackspace-monitoring-agent'
            end

            it 'update the latest monitoring agent' do
              chef_run.node.set['rackspace_cloudmonitoring']['agent']['version'] = 'latest'
              chef_run.converge('rackspace_cloudmonitoring::agent')
              expect(chef_run).to upgrade_package 'rackspace-monitoring-agent'
            end

            it 'enable the monitoring agent' do
              expect(chef_run).to enable_service 'rackspace-monitoring-agent'
            end

            it 'populate the plugin directory' do
              expect(chef_run).to create_remote_directory('rackspace_cloudmonitoring_plugins_rackspace_cloudmonitoring')
            end
          end

          describe 'without explicit token and ID' do
            before :each do
              chef_run.node.set['rackspace']['cloud_credentials']['username'] = 'IfThisHitsTheApiSomethingIsBusted'
              chef_run.node.set['rackspace']['cloud_credentials']['api_key']  = 'SuchFakePassword.VeryMock.Wow.'
              chef_run.converge('rackspace_cloudmonitoring::agent')
            end

            it 'include the default recipe' do
              expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::default'
            end

            it 'create the config tile' do
              expect(chef_run).to create_template '/etc/rackspace-monitoring-agent.cfg'
            end

            #
            # Current no check for the repo, I don't see any repostitory machers in https://github.com/sethvargo/chefspec/tree/master/lib/chefspec/api
            # Test kitchen will catch that, though.
            #

            it 'install the monitoring agent pinned to a version' do
              chef_run.node.set['rackspace_cloudmonitoring']['agent']['version'] = '1.2.3'
              chef_run.converge('rackspace_cloudmonitoring::agent')
              expect(chef_run).to install_package 'rackspace-monitoring-agent'
            end

            it 'update the latest monitoring agent' do
              chef_run.node.set['rackspace_cloudmonitoring']['agent']['version'] = 'latest'
              chef_run.converge('rackspace_cloudmonitoring::agent')
              expect(chef_run).to upgrade_package 'rackspace-monitoring-agent'
            end

            it 'should update the agent_token' do
              expect(chef_run).to create_monitoring_agent_token 'Fauxhai'
            end

            it 'enable the monitoring agent' do
              expect(chef_run).to enable_service 'rackspace-monitoring-agent'
            end

            it 'create the plugin directory' do
              expect(chef_run).to create_directory('/usr/lib/rackspace-monitoring-agent/plugins')
            end

            it 'populate the plugin directory' do
              expect(chef_run).to create_remote_directory('rackspace_cloudmonitoring_plugins_rackspace_cloudmonitoring')
            end
          end
        end
      end
    end
  end
end
