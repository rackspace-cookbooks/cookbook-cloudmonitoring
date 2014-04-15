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

def init_common_monitors_spec_alarm_tests
  chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = 'Test Default Plan'
  chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
  chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
    'Test Check' => {
      'type'  => 'Test Type',
      'alarm' => {
        'CRITICAL' => {
          'conditional' => 'test conditional'
        }
      }
    }
  }
end

describe 'rackspace_cloudmonitoring::monitors' do
  rackspace_cloudmonitoring_test_platforms.each do |platform, versions|
    describe "on #{platform}" do
      versions.each do |version|
        describe version do
          let(:chef_run) do
            ChefSpec::Runner.new(
                                 platform: platform.to_s,
                                 version: version.to_s
                                 ) do |node|
              node.set['rackspace_cloudmonitoring']['mock'] = true
              node.set['rackspace']['cloud_credentials']['username'] = 'IfThisHitsTheApiSomethingIsBusted'
              node.set['rackspace']['cloud_credentials']['api_key']  = 'SuchFakePassword.VeryMock.Wow.'
              node.set['rackspace_cloudmonitoring']['config']['agent']['id']    = 'rackspacerules'
              node.set['rackspace_cloudmonitoring']['config']['agent']['token'] = 'kittenmittens'
            end
          end

          describe 'include recipes' do
            before :each do
              chef_run.converge('rackspace_cloudmonitoring::agent')
            end

            it 'default' do
              expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::default'
            end

            it 'agent' do
              expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::agent'
            end
          end

          describe 'configure the entity' do
            before :each do
              chef_run.node.set['rackspace_cloudmonitoring']['config']['agent']['id'] = 'Test Agent ID'
              chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']         = 'Test Entity Label'
              chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_method'] = 'Test Search Method'
              chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_ip']     = 'Test Search IP'
              chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['ip_addresses']  = { default: 'Test Search IP' }
              chef_run.converge('rackspace_cloudmonitoring::monitors')
            end

            it 'agent_id' do
              expect(chef_run).to create_monitoring_entity('Test Entity Label').with(agent_id: 'Test Agent ID')
            end

            it 'search_method' do
              expect(chef_run).to create_monitoring_entity('Test Entity Label').with(search_method: 'Test Search Method')
            end

            it 'search_ip' do
              expect(chef_run).to create_monitoring_entity('Test Entity Label').with(search_ip: 'Test Search IP')
            end

            it 'ip_addresses' do
              expect(chef_run).to create_monitoring_entity('Test Entity Label').with(ip_addresses: { 'default' => 'Test Search IP' })
            end

          end

          describe 'configure checks' do
            describe 'with default values:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                    'type'  => 'Test Type'
                  }
                }
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              it 'monitors_defaults entity_chef_label' do
                expect(chef_run).to create_monitoring_check('Test Check').with(entity_chef_label: 'Test Entity Label')
              end

              it 'monitors hash type' do
                expect(chef_run).to create_monitoring_check('Test Check').with(type: 'Test Type')
              end

              it 'monitors_defaults period' do
                expect(chef_run).to create_monitoring_check('Test Check').with(period: 1234)
              end

              it 'monitors_defaults timeout' do
                expect(chef_run).to create_monitoring_check('Test Check').with(timeout: 5678)
              end

              it 'default details' do
                expect(chef_run).to create_monitoring_check('Test Check').with(details: nil)
              end

              it 'default disabled' do
                expect(chef_run).to create_monitoring_check('Test Check').with(disabled: false)
              end

              it 'default metadata' do
                expect(chef_run).to create_monitoring_check('Test Check').with(metadata: nil)
              end

              it 'default target_alias' do
                expect(chef_run).to create_monitoring_check('Test Check').with(target_alias: nil)
              end

              it 'default target_hostname' do
                expect(chef_run).to create_monitoring_check('Test Check').with(target_hostname: nil)
              end

              it 'default target_resolver' do
                expect(chef_run).to create_monitoring_check('Test Check').with(target_resolver: nil)
              end

              it 'default monitoring_zones_poll' do
                expect(chef_run).to create_monitoring_check('Test Check').with(monitoring_zones_poll: nil)
              end
            end

            describe 'with default values:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                    'type'     => 'Test Type',
                    'period'   => 9876,
                    'timeout'  => 8765,
                    'details'  => { test: 'Test details' },
                    'disabled' => true,
                    'metadata' => { test: 'Test metadata' },
                    'target_alias'    => 'Test target_alias',
                    'target_hostname' => 'Test target_hostname',
                    'target_resolver' => 'Test target_resolver',
                    'monitoring_zones_poll' => ['Test monitoring_zones_poll']

                  }
                }
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              it 'monitors_defaults entity_chef_label' do
                expect(chef_run).to create_monitoring_check('Test Check').with(entity_chef_label: 'Test Entity Label')
              end

              it 'monitors hash type' do
                expect(chef_run).to create_monitoring_check('Test Check').with(type: 'Test Type')
              end

              it 'monitors hash period' do
                expect(chef_run).to create_monitoring_check('Test Check').with(period: 9876)
              end

              it 'monitors hash timeout' do
                expect(chef_run).to create_monitoring_check('Test Check').with(timeout: 8765)
              end

              it 'monitors hash details' do
                expect(chef_run).to create_monitoring_check('Test Check').with(details: { 'test' => 'Test details' })
              end

              it 'monitors hash disabled' do
                expect(chef_run).to create_monitoring_check('Test Check').with(disabled: true)
              end

              it 'monitors hash metadata' do
                expect(chef_run).to create_monitoring_check('Test Check').with(metadata: { 'test' => 'Test metadata' })
              end

              it 'monitors hash target_alias' do
                expect(chef_run).to create_monitoring_check('Test Check').with(target_alias: 'Test target_alias')
              end

              it 'monitors hash target_hostname' do
                expect(chef_run).to create_monitoring_check('Test Check').with(target_hostname: 'Test target_hostname')
              end

              it 'monitors hash target_resolver' do
                expect(chef_run).to create_monitoring_check('Test Check').with(target_resolver: 'Test target_resolver')
              end

              it 'monitors hash monitoring_zones_poll' do
                expect(chef_run).to create_monitoring_check('Test Check').with(monitoring_zones_poll: ['Test monitoring_zones_poll'])
              end
            end

            describe 'in a loop:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {}
                3.times do |x|
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']["Test Check #{x}"] = { 'type'  => 'Test Type' }
                end
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              3.times do |x|
                it "create check #{x}" do
                  expect(chef_run).to create_monitoring_check("Test Check #{x}").with(type: 'Test Type')
                end
              end
            end # Loop describe
          end # Check describe

          describe 'configure alarms: ' do
            describe 'alarm bypass: 'do
              it 'does not create an alarm' do
                init_common_monitors_spec_alarm_tests
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['bypass_alarms'] = true
                chef_run.converge('rackspace_cloudmonitoring::monitors')
                expect(chef_run).to_not create_monitoring_alarm('Test Check alarm')
              end
            end

            describe 'alarm creation: ' do
              describe 'consecutive_count' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                end

                it 'uses values from node data' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['consecutive_count'] = 'Node Data Consecutive Count'
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(criteria: /^:set consecutiveCount=Node Data Consecutive Count$/)
                end

                it 'uses values from alarm data' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['consecutive_count'] = 'Node Data Consecutive Count'
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['consecutive_count'] = 'Alarm Data Consecutive Count'
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(criteria: /^:set consecutiveCount=Alarm Data Consecutive Count$/)
                end
              end

              describe 'state generation:' do
                it 'fails with no states or alarm_dsl' do
                  init_common_monitors_spec_alarm_tests
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm'] = {}
                  expect { chef_run.converge('rackspace_cloudmonitoring::monitors') }.to raise_exception
                end

                describe 'states array and helpers:' do
                  before :each do
                    init_common_monitors_spec_alarm_tests
                    chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm'].merge!(
                          'CRITICAL' => { 'conditional' => 'test CRITICAL conditional' },
                          'WARNING'  => { 'conditional' => 'test WARNING conditional' },
                          'states'   => [
                                         { 'state' => 'TestState1', 'conditional' => 'test TestState1 conditional' },
                                         { 'state' => 'TestState2', 'conditional' => 'test TestState2 conditional' },
                                         { 'state' => 'TestState3', 'conditional' => 'test TestState3 conditional' }
                                        ]
                                                                                                             )
                    chef_run.converge('rackspace_cloudmonitoring::monitors')
                  end

                  %w(CRITICAL WARNING TestState1 TestState2 TestState3).each do |state|
                    it "configures the #{state} state criteria" do
                      # Use a lazy regex, the tests for generate_alarm_dsl_block will check the exact DSL
                      expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(criteria: /^if \(.*#{state}.*\).*#{state}.*/)
                    end
                  end
                end
              end

              describe 'alarm_dsl usage:' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm'] = {}
                end

                [{ description: 'CRITICAL helper is specified', argument: { 'CRITICAL' => { 'conditional' => 'test CRITICAL conditional' } } },
                 { description: 'WARNING helper is specified', argument: { 'WARNING' => { 'conditional' => 'test WARNING conditional' } } },
                 { description: 'states array is populated', argument: { 'states' => [{ 'state' => 'TestState1', 'conditional' => 'test TestState1 conditional' }] } },
                 { description: 'ok_message is specified', argument: { 'ok_message' => 'All is well' } }
                ].each do |test_data|
                  it "fails if alarm_dsl and #{test_data[:description]}" do
                    chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm'].merge!(test_data[:argument])
                    chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['alarm_dsl'] = 'Test Alarm DSL'
                    expect { chef_run.converge('rackspace_cloudmonitoring::monitors') }.to raise_exception
                  end
                end

                it 'uses alarm_dsl for criteria' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['alarm_dsl'] = 'Test Alarm DSL'
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(criteria: 'Test Alarm DSL')
                end
              end

              describe 'ok_message usage:' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                end

                it 'Appends the default OK message without ok_message' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['ok_message'] = nil
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(criteria: /^return new AlarmStatus\(OK, 'Test Check is clear'\);$/)
                end

                it 'Appends the specified ok_message' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['ok_message'] = 'Test OK Message'
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(criteria: /^return new AlarmStatus\(OK, 'Test OK Message'\);$/)
                end
              end

              describe 'notification_plan_id' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                end

                it 'uses values from node data' do
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(notification_plan_id: 'Test Default Plan')
                end

                it 'uses values from alarm data' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['notification_plan_id'] = 'Test Alarm Plan'
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(notification_plan_id: 'Test Alarm Plan')
                end
              end

              describe 'disabled' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                end

                it 'defaults to false' do
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(disabled: false)
                end

                it 'uses values from alarm data' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['disabled'] = true
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(disabled: true)
                end
              end

              describe 'metadata' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                end

                it 'defaults to nil' do
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(metadata: nil)
                end

                it 'uses values from alarm data' do
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['metadata'] = { 'foo' => 'bar' }
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(metadata: { 'foo' => 'bar' })
                end
              end

              describe 'entity_chef_label and check_label' do
                before :each do
                  init_common_monitors_spec_alarm_tests
                  chef_run.converge('rackspace_cloudmonitoring::monitors')
                end

                it 'uses the node entity label' do
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(entity_chef_label: 'Test Entity Label')
                end

                it 'uses the check name' do
                  expect(chef_run).to create_monitoring_alarm('Test Check alarm').with(check_label: 'Test Check')
                end
              end
            end

            describe 'legacy alarm removal:' do
              before :each do
                init_common_monitors_spec_alarm_tests
              end

              # Explicitly test all logic states
              [false, true].each do |node_setting|
                [false, true, nil].each do |alarm_setting|
                  expected_state = alarm_setting.nil? ? node_setting : alarm_setting
                  if expected_state
                    it "deletes legacy alarms when node remove_old_alarms is #{node_setting} and alarm remove_old_alarms is #{alarm_setting}" do
                      chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_old_alarms'] = node_setting
                      chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['remove_old_alarms'] = alarm_setting
                      chef_run.converge('rackspace_cloudmonitoring::monitors')
                      expect(chef_run).to delete_monitoring_alarm('Test Check CRITICAL alarm')
                      expect(chef_run).to delete_monitoring_alarm('Test Check WARNING alarm')
                    end
                  else
                    it "does not delete legacy alarms when node remove_old_alarms is #{node_setting} and alarm remove_old_alarms is #{alarm_setting}" do
                      chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_old_alarms'] = node_setting
                      chef_run.node.set['rackspace_cloudmonitoring']['monitors']['Test Check']['alarm']['remove_old_alarms'] = alarm_setting
                      chef_run.converge('rackspace_cloudmonitoring::monitors')
                      expect(chef_run).to_not delete_monitoring_alarm('Test Check CRITICAL alarm')
                      expect(chef_run).to_not delete_monitoring_alarm('Test Check WARNING alarm')
                    end
                  end
                end
              end
            end

            describe 'orphan alarm removal:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = 'Test Default Plan'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                    'type'  => 'Test Type'
                  }
                }
              end

              it 'removes orphaned alarms when node remove_orphan_alarms is true' do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_orphan_alarms'] = true
                chef_run.converge('rackspace_cloudmonitoring::monitors')
                expect(chef_run).to delete_monitoring_alarm('Test Check alarm')
              end

              it 'does not remove orphaned alarms when node remove_orphan_alarms is true' do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_orphan_alarms'] = false
                chef_run.converge('rackspace_cloudmonitoring::monitors')
                expect(chef_run).to_not delete_monitoring_alarm('Test Check alarm')
              end
            end

          end # Alarm describe
        end # Version loop
      end
    end
  end
end
