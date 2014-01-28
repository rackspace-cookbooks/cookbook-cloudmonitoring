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
            ChefSpec::Runner.new(platform: platform.to_s, version: version.to_s) do |node|
              node.set['rackspace_cloudmonitoring']['mock'] = true
              node.set['rackspace']['cloud_credentials']['username'] = 'IfThisHitsTheApiSomethingIsBusted'
              node.set['rackspace']['cloud_credentials']['api_key']  = 'SuchFakePassword.VeryMock.Wow.'

              # Mocked fog currently returns a nil token, causing the agent recipe to fail
              node.set['rackspace_cloudmonitoring']['config']['agent']['id']    = 'rackspacerules'
              node.set['rackspace_cloudmonitoring']['config']['agent']['token'] = 'kittenmittens'
            end.converge('rackspace_cloudmonitoring::monitors')
          end

          it 'include the default recipe' do
            expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::default'
          end

          it 'include the agent recipe' do
            expect(chef_run).to include_recipe 'rackspace_cloudmonitoring::agent'
          end

          #
          # TODO: Uhhh, write the rest of the tests?
          #

        end
      end
    end
  end
end
