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

require_relative '../../../libraries/MonitorsRecipeHelpers.rb'
include Opscode::Rackspace::Monitoring

describe 'MonitorsRecipeHelpers' do
  describe 'generate_alarm_dsl_block' do
    it 'fails if no state is specified' do
      expect { MonitorsRecipeHelpers.generate_alarm_dsl_block({}, nil, nil) }.to raise_error
    end

    %w(alarm_dsl metadata notification_plan_id).each do |deprecated_option|
      it "fails if deprecated option #{deprecated_option} is specified" do
        expect { MonitorsRecipeHelpers.generate_alarm_dsl_block({ deprecated_option => 'foo' }, nil, 'TestState') }.to raise_error
      end
    end

    it 'returns an empty string when disabled is true' do
      MonitorsRecipeHelpers.generate_alarm_dsl_block({ 'disabled' => true }, nil, 'TestState').should eql ''
    end

    it 'fails when conditional is unset' do
      expect { MonitorsRecipeHelpers.generate_alarm_dsl_block({}, nil, 'TestState') }.to raise_error
    end

    [{ description: 'default_state', hash_state: nil, expected_state: 'TestState' },
     { description: 'hash', hash_state: 'HashState', expected_state: 'HashState' }].each do |state_test|
      # Embed message_test data in the state_test loop as the expected_message uses the state
      [{ description: 'Default', hash_message: nil, expected_message: "TestCheck is past #{state_test[:expected_state]} threshold" },
       { description: 'hash', hash_message: 'Test Message', expected_message: 'Test Message' }].each do |message_test|
        it "Returns proper DSL using the #{state_test[:description]} state and #{message_test[:description]} message" do
          MonitorsRecipeHelpers.generate_alarm_dsl_block({ 'conditional' => 'TestConditional',
                                                           'state'       => state_test[:hash_state],
                                                           'message'     => message_test[:hash_message]
                                                           }, 'TestCheck', 'TestState'
              ).should eql "if (TestConditional) { return new AlarmStatus(#{state_test[:expected_state]}, '#{message_test[:expected_message]}'); }\n"
        end
      end
    end

  end
end
