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

require_relative '../../../libraries/mock_data.rb'
include Opscode::Rackspace::Monitoring::MockData

#
# TODO: This code is not DRY.
#
describe 'mock_data' do
  describe MockMonitoring do
    describe '#new' do
      it 'takes parameters and is a Opscode::Rackspace::Monitoring::MockData::MockMonitoring object' do
        @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                       rackspace_username: 'sandwitches')
        @mock_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoring
      end

      it 'fails if rackspace_api_key is missing' do
        expect { MockMonitoring.new(rackspace_username: 'sandwitches') }.to raise_error
      end

      it 'fails if rackspace_username is missing' do
        expect { MockMonitoring.new(rackspace_api_key: 'porkchop') }.to raise_error
      end
    end

    describe '#agent_tokens' do
      # Using :all instead of :each to allow the destroy test to use the value added by the save test.
      before :all do
        @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                       rackspace_username: 'sandwitches')
      end

      it 'should be empty initially' do
        @mock_obj.agent_tokens.length.should eql 0
      end

      describe '#new' do
        it 'should return a Opscode::Rackspace::Monitoring::MockData::MockMonitoringAgentToken object' do
          @mock_obj.agent_tokens.new.should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoringAgentToken
        end

        [:label].each do |arg|
          it "should accept #{arg} as an option" do
            test_obj = @mock_obj.agent_tokens.new(arg.to_s => 'foobar')
            test_obj.send(arg).should_not eql nil
          end
        end

        it 'should not accept bogus arguments' do
          expect { @mock_obj.agent_tokens.new(bogus: 'data') }.to raise_error
        end

        it 'should not modify the parent array' do
          @mock_obj.agent_tokens.length.should eql 0
        end
      end

      [:label].each do |arg|
        describe "##{arg}" do
          it 'should be a getter and a setter' do
            test_obj = @mock_obj.agent_tokens.new
            test_obj.send(arg).should eql nil
            test_obj.send("#{arg}=", 'Test Data')
            test_obj.send(arg).should eql 'Test Data'
          end
        end
      end

      describe '#id' do
        it 'should not be nil' do
          test_obj = @mock_obj.agent_tokens.new
          test_obj.id.should_not eql nil
        end
      end

      describe '#token' do
        it 'should not be nil' do
          test_obj = @mock_obj.agent_tokens.new
          test_obj.token.should_not eql nil
        end
      end

      describe '#save' do
        it 'should save the token into the parent' do
          @mock_obj.agent_tokens.length.should eql 0
          test_obj = @mock_obj.agent_tokens.new
          test_obj.save
          @mock_obj.agent_tokens.length.should eql 1
          @mock_obj.agent_tokens[0].should eql test_obj
        end

        it 'should overwrite tokens with duplicate IDs' do
          @mock_obj.agent_tokens.length.should eql 1
          test_obj = @mock_obj.agent_tokens[0]

          test_obj.label.should_not eql 'Test label 2'
          test_obj.label = 'Test label 2'

          test_obj.save
          @mock_obj.agent_tokens.length.should eql 1
          @mock_obj.agent_tokens[0].should eql test_obj
        end
      end

      describe '#destroy' do
        it 'should remove the token from the parent' do
          @mock_obj.agent_tokens.length.should eql 1
          target = @mock_obj.agent_tokens[0]
          target.destroy
          @mock_obj.agent_tokens.length.should eql 0
        end
      end

      describe '#compare?' do
        it 'should return true if the objects are the same' do
          test_obj  = @mock_obj.agent_tokens.new
          test_obj2 = test_obj.dup
          test_obj.compare?(test_obj2).should eql true
        end

        it 'should return false if the objects are different' do
          test_obj  = @mock_obj.agent_tokens.new
          test_obj2 = @mock_obj.agent_tokens.new
          test_obj.compare?(test_obj2).should eql false
        end
      end

      describe '#all' do
        before :each do
          @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                         rackspace_username: 'sandwitches')
          10.times do
            @mock_obj.agent_tokens.new.save
          end
        end

        it 'returns all objects when object count < limit' do
          all_output = @mock_obj.agent_tokens.all(limit: 20, marker: nil)
          all_output.should eql @mock_obj.agent_tokens
          all_output.marker.should eql nil
        end

        it 'returns all objects when object count == limit' do
          all_output = @mock_obj.agent_tokens.all(limit: 10, marker: nil)
          all_output.should eql @mock_obj.agent_tokens
          all_output.marker.should eql nil
        end

        it 'Paginates when when object count > limit' do
          all_output = @mock_obj.agent_tokens.all(limit: 5, marker: nil)
          all_output.should eql @mock_obj.agent_tokens[0..4]
          all_output.marker.should eql @mock_obj.agent_tokens[5].id

          all_output = @mock_obj.agent_tokens.all(limit: 5, marker: all_output.marker)
          all_output.should eql @mock_obj.agent_tokens[5..9]
          all_output.marker.should eql nil
        end

        it 'Fails when limit < 1' do
          expect { @mock_obj.agent_tokens.all(limit: 0, marker: nil) }.to raise_exception
        end
        it 'Fails when limit > 1000' do
          expect { @mock_obj.agent_tokens.all(limit: 1001, marker: nil) }.to raise_exception
        end
      end
    end

    describe '#entities' do
      # Using :all instead of :each to allow the destroy test to use the value added by the save test.
      before :all do
        @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                       rackspace_username: 'sandwitches')
      end

      it 'should be empty initially' do
        @mock_obj.entities.length.should eql 0
      end

      describe '#new' do
        it 'should return a Opscode::Rackspace::Monitoring::MockData::MockMonitoringEntity object' do
          @mock_obj.entities.new.should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoringEntity
        end

        [:label, :metadata, :ip_addresses, :agent_id, :managed, :uri].each do |arg|
          it "should accept #{arg} as an option" do
            test_entity = @mock_obj.entities.new(arg.to_s => 'foobar')
            test_entity.send(arg).should_not eql nil
          end
        end

        it 'should not accept bogus arguments' do
          expect { @mock_obj.entities.new(bogus: 'data') }.to raise_error
        end

        it 'should not modify the parent array' do
          @mock_obj.entities.length.should eql 0
        end
      end

      [:label, :metadata, :ip_addresses, :agent_id, :managed, :uri].each do |arg|
        describe "##{arg}" do
          it 'should be a getter and a setter' do
            test_entity = @mock_obj.entities.new
            test_entity.send(arg).should eql nil
            test_entity.send("#{arg}=", 'Test Data')
            test_entity.send(arg).should eql 'Test Data'
          end
        end
      end

      # ID: Special case: preset by new()
      [:id].each do |arg|
        describe "##{arg}" do
          it 'should be a getter and a setter' do
            test_entity = @mock_obj.entities.new
            test_entity.send(arg).should_not eql 'Test Data'
            test_entity.send("#{arg}=", 'Test Data')
            test_entity.send(arg).should eql 'Test Data'
          end
        end
      end

      describe '#save' do
        it 'should save the entity into the parent' do
          @mock_obj.entities.length.should eql 0
          test_entity = @mock_obj.entities.new
          test_entity.save
          @mock_obj.entities.length.should eql 1
          @mock_obj.entities[0].should eql test_entity
        end

        it 'should overwrite entities with duplicate IDs' do
          @mock_obj.entities.length.should eql 1
          test_obj = @mock_obj.entities[0]

          test_obj.label.should_not eql 'Test label 2'
          test_obj.label = 'Test label 2'

          test_obj.save
          @mock_obj.entities.length.should eql 1
          @mock_obj.entities[0].should eql test_obj
        end
      end

      describe '#destroy' do
        it 'should remove the entity from the parent' do
          @mock_obj.entities.length.should eql 1
          target = @mock_obj.entities[0]
          target.destroy
          @mock_obj.entities.length.should eql 0
        end
      end

      describe '#compare?' do
        it 'should return true if the objects are the same' do
          test_entity = @mock_obj.entities.new
          test_entity2 = test_entity.dup
          test_entity.compare?(test_entity2).should eql true
        end

        it 'should return false if the objects are different' do
          test_entity  =  @mock_obj.entities.new
          test_entity2 = @mock_obj.entities.new
          test_entity.compare?(test_entity2).should eql false
        end
      end

      describe '#all' do
        before :each do
          @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                         rackspace_username: 'sandwitches')
          10.times do
            @mock_obj.entities.new.save
          end
        end

        it 'returns all objects when object count < limit' do
          all_output = @mock_obj.entities.all(limit: 20, marker: nil)
          all_output.should eql @mock_obj.entities
          all_output.marker.should eql nil
        end

        it 'returns all objects when object count == limit' do
          all_output = @mock_obj.entities.all(limit: 10, marker: nil)
          all_output.should eql @mock_obj.entities
          all_output.marker.should eql nil
        end

        it 'Paginates when when object count > limit' do
          all_output = @mock_obj.entities.all(limit: 5, marker: nil)
          all_output.should eql @mock_obj.entities[0..4]
          all_output.marker.should eql @mock_obj.entities[5].id

          all_output = @mock_obj.entities.all(limit: 5, marker: all_output.marker)
          all_output.should eql @mock_obj.entities[5..9]
          all_output.marker.should eql nil
        end

        it 'Fails when limit < 1' do
          expect { @mock_obj.entities.all(limit: 0, marker: nil) }.to raise_exception
        end
        it 'Fails when limit > 1000' do
          expect { @mock_obj.entities.all(limit: 1001, marker: nil) }.to raise_exception
        end
      end

      describe '#checks' do
        before :all do
          @test_entity = @mock_obj.entities.new
        end

        describe '#new' do
          it 'should fail without type argument' do
            expect { @test_entity.checks.new }.to raise_error
          end

          it 'should return a Opscode::Rackspace::Monitoring::MockData::MockMonitoringCheck object' do
            @test_entity.checks.new('type' => 'dummy ').should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoringCheck
          end

          [:label, :metadata, :target_alias, :target_resolver, :target_hostname, :period, :timeout, :details, :disabled, :monitoring_zones_poll].each do |arg|
            it "should accept #{arg} as an option" do
              test_check = @test_entity.checks.new('type' => 'dummy', arg.to_s => 'foobar')
              test_check.send(arg).should_not eql nil
            end
          end

          it 'should not accept bogus arguments' do
            expect { @test_entity.checks.new('type' => 'dummy', bogus: 'data') }.to raise_error
          end

          it 'should not modify the parent array' do
            @test_entity.checks.length.should eql 0
          end
        end

        [:label, :metadata, :target_alias, :target_resolver, :target_hostname, :period, :timeout, :details, :disabled, :monitoring_zones_poll].each do |arg|
          describe "##{arg}" do
            it 'should be a getter and a setter' do
              test_check = @test_entity.checks.new('type' => 'dummy ')
              test_check.send(arg).should eql nil
              test_check.send("#{arg}=", 'Test Data')
              test_check.send(arg).should eql 'Test Data'
            end
          end
        end

        # Special cases: preset by new()
        [:id, :entity, :type].each do |arg|
          describe "##{arg}" do
            it 'should be a getter and a setter' do
              test_check = @test_entity.checks.new('type' => 'dummy ')
              test_check.send(arg).should_not eql 'Test Data'
              test_check.send("#{arg}=", 'Test Data')
              test_check.send(arg).should eql 'Test Data'
            end
          end
        end

        describe '#save' do
          it 'should save the check into the parent' do
            @test_entity.checks.length.should eql 0
            test_check = @test_entity.checks.new('type' => 'dummy ')
            test_check.save
            @test_entity.checks.length.should eql 1
            @test_entity.checks[0].should eql test_check
          end

          it 'should overwrite checks with duplicate IDs' do
            @test_entity.checks.length.should eql 1
            test_obj = @test_entity.checks[0]

            test_obj.label.should_not eql 'Test label 2'
            test_obj.label = 'Test label 2'

            test_obj.save
            @test_entity.checks.length.should eql 1
            @test_entity.checks[0].should eql test_obj
          end
        end

        describe '#destroy' do
          it 'should remove the check from the parent' do
            @test_entity.checks.length.should eql 1
            target = @test_entity.checks[0]
            target.destroy
            @test_entity.checks.length.should eql 0
          end
        end

        describe '#compare?' do
          it 'should return true if the objects are the same' do
            test_check = @test_entity.checks.new('type' => 'dummy ')
            test_check2 = test_check.dup
            test_check.compare?(test_check2).should eql true
          end

          it 'should return false if the objects are different' do
            test_check =  @test_entity.checks.new('type' => 'dummy ')
            test_check2 = @test_entity.checks.new('type' => 'dummy ')
            test_check.compare?(test_check2).should eql false
          end
        end

        describe '#all' do
          before :each do
            @test_entity = @mock_obj.entities.new
            10.times do
              @test_entity.checks.new('type' => 'dummy ').save
            end
          end

          it 'returns all objects when object count < limit' do
            all_output = @test_entity.checks.all(limit: 20, marker: nil)
            all_output.should eql @test_entity.checks
            all_output.marker.should eql nil
          end

          it 'returns all objects when object count == limit' do
            all_output = @test_entity.checks.all(limit: 10, marker: nil)
            all_output.should eql @test_entity.checks
            all_output.marker.should eql nil
          end

          it 'Paginates when when object count > limit' do
            all_output = @test_entity.checks.all(limit: 5, marker: nil)
            all_output.should eql @test_entity.checks[0..4]
            all_output.marker.should eql @test_entity.checks[5].id

            all_output = @test_entity.checks.all(limit: 5, marker: all_output.marker)
            all_output.should eql @test_entity.checks[5..9]
            all_output.marker.should eql nil
          end

          it 'Fails when limit < 1' do
            expect { @test_entity.checks.all(limit: 0, marker: nil) }.to raise_exception
          end
          it 'Fails when limit > 1000' do
            expect { @test_entity.checks.all(limit: 1001, marker: nil) }.to raise_exception
          end
        end
      end

      describe '#alarms' do
      # Using :all instead of :each to allow the destroy test to use the value added by the save test.
        before :all do
          @test_entity = @mock_obj.entities.new
        end

        describe '#new' do
          it 'should fail without check_id argument' do
            expect { @test_entity.alarms.new('notification_plan_id' => 'seven ') }.to raise_error
          end

          it 'should fail without notification_plan_id argument' do
            expect { @test_entity.alarms.new('check' => 'three ') }.to raise_error
          end

          it 'should return a Opscode::Rackspace::Monitoring::MockData::MockMonitoringAlarm object' do
            @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ').should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoringAlarm
          end

          [:check, :label, :criteria, :notification_plan_id, :disabled, :metadata].each do |arg|
            it "should accept #{arg} as an option" do
              test_check = @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven', arg.to_s => 'foobar')
              test_check.send(arg).should_not eql nil
            end
          end

          it 'should not accept bogus arguments' do
            expect { @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven', bogus: 'data') }.to raise_error
          end

          it 'should not modify the parent array' do
            @test_entity.alarms.length.should eql 0
          end
        end

        [:label, :criteria, :disabled, :metadata].each do |arg|
          describe "##{arg}" do
            it 'should be a getter and a setter' do
              test_check = @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ')
              test_check.send(arg).should eql nil
              test_check.send("#{arg}=", 'Test Data')
              test_check.send(arg).should eql 'Test Data'
            end
          end
        end

        # Special cases: preset by new()
        [:id, :entity, :check, :notification_plan_id].each do |arg|
          describe "##{arg}" do
            it 'should be a getter and a setter' do
              test_check = @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ')
              test_check.send(arg).should_not eql 'Test Data'
              test_check.send("#{arg}=", 'Test Data')
              test_check.send(arg).should eql 'Test Data'
            end
          end
        end

        describe '#save' do
          it 'should save the alarm into the parent' do
            @test_entity.alarms.length.should eql 0
            test_check = @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ')
            test_check.save
            @test_entity.alarms.length.should eql 1
            @test_entity.alarms[0].should eql test_check
          end

          it 'should overwrite alarms with duplicate IDs' do
            @test_entity.alarms.length.should eql 1
            test_obj = @test_entity.alarms[0]

            test_obj.label.should_not eql 'Test label 2'
            test_obj.label = 'Test label 2'

            test_obj.save
            @test_entity.alarms.length.should eql 1
            @test_entity.alarms[0].should eql test_obj
          end

        end

        describe '#destroy' do
          it 'should remove the alarm from the parent' do
            @test_entity.alarms.length.should eql 1
            target = @test_entity.alarms[0]
            target.destroy
            @test_entity.alarms.length.should eql 0
          end
        end

        describe '#compare?' do
          it 'should return true if the objects are the same' do
            test_check = @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ')
            test_check2 = test_check.dup
            test_check.compare?(test_check2).should eql true
          end

          it 'should return false if the objects are different' do
            test_check =  @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ')
            test_check2 = @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ')
            test_check.compare?(test_check2).should eql false
          end
        end

        describe '#all' do
          before :each do
            @test_entity = @mock_obj.entities.new
            10.times do
              @test_entity.alarms.new('check' => 'three', 'notification_plan_id' => 'seven ').save
            end
          end

          it 'returns all objects when object count < limit' do
            all_output = @test_entity.alarms.all(limit: 20, marker: nil)
            all_output.should eql @test_entity.alarms
            all_output.marker.should eql nil
          end

          it 'returns all objects when object count == limit' do
            all_output = @test_entity.alarms.all(limit: 10, marker: nil)
            all_output.should eql @test_entity.alarms
            all_output.marker.should eql nil
          end

          it 'Paginates when when object count > limit' do
            all_output = @test_entity.alarms.all(limit: 5, marker: nil)
            all_output.should eql @test_entity.alarms[0..4]
            all_output.marker.should eql @test_entity.alarms[5].id

            all_output = @test_entity.alarms.all(limit: 5, marker: all_output.marker)
            all_output.should eql @test_entity.alarms[5..9]
            all_output.marker.should eql nil
          end

          it 'Fails when limit < 1' do
            expect { @test_entity.alarms.all(limit: 0, marker: nil) }.to raise_exception
          end
          it 'Fails when limit > 1000' do
            expect { @test_entity.alarms.all(limit: 1001, marker: nil) }.to raise_exception
          end
        end
      end
    end

    describe '#alarm_examples' do
      before :all do
        @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                       rackspace_username: 'sandwitches')
      end

      it 'should contain seed data' do
        @mock_obj.alarm_examples.length.should eql 3
      end

      it 'should contain MockMonitoringAlarmExample classes' do
        @mock_obj.alarm_examples[0].should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoringAlarmExample
      end

      describe '#evaluate' do
        before :all do
          @mock_obj = MockMonitoring.new(rackspace_api_key:  'porkchop',
                                         rackspace_username: 'sandwitches')
        end

        it 'should error with a bad id' do
          expect { @mock_obj.alarm_examples.evaluate('Bad Data') }.to raise_exception
        end

        it 'should error with option mismatches' do
          expect { @mock_obj.alarm_examples.evaluate('remote.http_body_match_1',  'Bad Option' => 'Bad Data') }.to raise_exception
        end

        it 'should return a MockMonitoringAlarmExample when the options are correct' do
          ret_val = @mock_obj.alarm_examples.evaluate('remote.http_body_match_1',  'string' => 'Some search thing')
          ret_val.should be_an_instance_of MockMonitoringAlarmExample
          ret_val.bound_criteria.should be_an_instance_of String
        end
      end
    end
  end
end
