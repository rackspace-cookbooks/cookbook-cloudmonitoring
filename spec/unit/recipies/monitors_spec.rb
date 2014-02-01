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

          describe 'configure alarms' do
            describe 'without mandatory options:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                      'type'  => 'Test Type',
                      'alarm' => {
                      'Test Alarm' => {}
                    }
                  }
                }
              end

              it 'fail without conditional' do
                expect { chef_run.converge('rackspace_cloudmonitoring::monitors') }.to raise_exception
              end
            end

            describe 'with default values:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = 'Test Default Plan'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                    'type'  => 'Test Type',
                    'alarm' => {
                      'Test Alarm' => {
                        'conditional' => 'test conditional'
                      }
                    }
                  }
                }
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              it 'monitors_defaults entity_chef_label' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(entity_chef_label: 'Test Entity Label')
              end

              it 'parent check label' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(check_label: 'Test Check')
              end

              it 'default generated criteria' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(
                   criteria: "if (test conditional) { return Test Alarm, 'Test Check is past Test Alarm threshold' }"
                                                                                                )
              end

              it 'monitors hash disabled' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(disabled: false)
              end

              it 'monitors hash metadata' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(metadata: nil)
              end

              it 'monitors_defaults notification_plan_id' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(notification_plan_id: 'Test Default Plan')
              end
            end

            describe 'with values inherited from the check:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = 'Test Default Plan'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                    'notification_plan_id' => 'Test Check Notification Plan',
                    'type'  => 'Test Type',
                    'alarm' => {
                      'Test Alarm' => {
                        'conditional' => 'test conditional'
                      }
                    }
                  }
                }
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              it 'monitors_defaults entity_chef_label' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(entity_chef_label: 'Test Entity Label')
              end

              it 'parent check label' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(check_label: 'Test Check')
              end

              it 'default generated criteria' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(
                    criteria: "if (test conditional) { return Test Alarm, 'Test Check is past Test Alarm threshold' }"
                                                                                                )
              end

              it 'monitors hash disabled' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(disabled: false)
              end

              it 'monitors hash metadata' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(metadata: nil)
              end

              it 'monitors_defaults notification_plan_id' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(notification_plan_id: 'Test Check Notification Plan')
              end
            end

            describe 'with specified values:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = 'Test Default Plan'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {
                  'Test Check' => {
                    'notification_plan_id' => 'Test Check Notification Plan',
                    'type'  => 'Test Type',
                    'alarm' => {
                      'Test Alarm' => {
                        'conditional' => 'test conditional',
                        'notification_plan_id' => 'Test Alarm Notification Plan',
                        'state'    => 'Test Alarm State',
                        'disabled' => true,
                        'metadata' => { test: 'Test Metadata' }
                      }
                    }
                  }
                }
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              it 'monitors_defaults entity_chef_label' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(entity_chef_label: 'Test Entity Label')
              end

              it 'parent check label' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(check_label: 'Test Check')
              end

              it 'specific generated criteria' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(
                    criteria: "if (test conditional) { return Test Alarm State, 'Test Check is past Test Alarm State threshold' }"
                                                                                                )
              end

              it 'specified disabled' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(disabled: true)
              end

              it 'specified metadata' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(metadata: { 'test' => 'Test Metadata' })
              end

              it 'specified notification_plan_id' do
                expect(chef_run).to create_monitoring_alarm('Test Check Test Alarm alarm').with(notification_plan_id: 'Test Alarm Notification Plan')
              end
            end

            describe 'in a loop:' do
              before :each do
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] = 'Test Default Plan'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']  = 'Test Entity Label'
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['period']  = 1234
                chef_run.node.set['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] = 5678

                chef_run.node.set['rackspace_cloudmonitoring']['monitors'] = {}
                3.times do |x|
                  chef_run.node.set['rackspace_cloudmonitoring']['monitors']["Test Check #{x}"] = {
                    'type'  => 'Test Type',
                    'alarm' => {}
                  }
                  3.times do |y|
                    chef_run.node.set['rackspace_cloudmonitoring']['monitors']["Test Check #{x}"]['alarm']["Test Alarm #{y}"] = {
                      'conditional' => 'test conditional'
                    }
                  end
                end
                chef_run.converge('rackspace_cloudmonitoring::monitors')
              end

              3.times do |x|
                3.times do |y|
                  it "create alarm #{y} under check #{x}" do
                    expect(chef_run).to create_monitoring_alarm("Test Check #{x} Test Alarm #{y} alarm")
                  end
                end
              end
            end # Loop describe

          end # Alarm describe
        end # Version loop
      end
    end
  end
end
