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

describe 'rackspace_cloudmonitoring::monitors' do
  rackspace_cloudmonitoring_test_platforms.each do |platform, versions|
    describe "on #{platform}" do
      versions.each do |version|
        describe version do
          let(:chef_run) do
            ChefSpec::Runner.new(platform: platform.to_s, 
                                 version: version.to_s,
                                 step_into: ['rackspace_cloudmonitoring_agent_token',
                                             'rackspace_cloudmonitoring_alarm',
                                             'rackspace_cloudmonitoring_check',
                                             'rackspace_cloudmonitoring_entity']) do |node|
              node.set['rackspace_cloudmonitoring']['mock'] = true
              node.set['rackspace']['cloud_credentials']['username'] = 'IfThisHitsTheApiSomethingIsBusted'
              node.set['rackspace']['cloud_credentials']['api_key']  = 'SuchFakePassword.VeryMock.Wow.'
              node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label'] = "Test Entity Label"
              node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = "Test Plan"

              node.set['rackspace_cloudmonitoring']['monitors'] = {
                'load' => { 'type'  => 'agent.load_average',
                  'alarm' => {
                    'CRITICAL' => { 'conditional' => "metric['5m'] > 16", },
                  },
                }
              }
              
            end.converge('rackspace_cloudmonitoring::monitors')
          end
          
          it 'include the default recipe' do
            expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::default'
          end
          
          it 'include the agent recipe' do
            expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::agent'
          end

          it 'should create the entity' do
            expect(chef_run).to create_monitoring_entity "Test Entity Label"
          end

          it 'should create the load check' do
            expect(chef_run).to create_monitoring_check 'load'
          end

          it 'should create the load critical alarm' do
            expect(chef_run).to create_monitoring_alarm 'load CRITICAL alarm'
          end
        end
      end
    end
  end
end
