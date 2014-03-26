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

require_relative '../../../libraries/alarm_hwrp.rb'
require_relative 'hwrp_helpers.rb'

module AlarmHWRPTestMocks
  # Dog simple mock class to ensure we're calling the underlying class with the right arguments
  # Actual behavior of the underlying classes is tested by their respective tests
  class CMAlarmHWRPMock
    attr_accessor :credentials, :obj, :update_args, :delete_called, :entity_label, :label, :lookup_label, :example_alarm_id, :example_alarm_values
    attr_writer   :obj

    def initialize(my_credentials, my_entity_label, my_label)
      @credentials = my_credentials
      @entity_label = my_entity_label
      @label = my_label
      @delete_called = false
    end

    def update(args = {})
      @update_args = args
      return true
    end

    def delete
      @delete_called = true
      return true
    end
                               # We're mocking here, and attr_writer doesn't behave the same
    def lookup_by_label(label) # rubocop:disable TrivialAccessors
      @lookup_label = label
    end

    def example_alarm(id, values)
      @example_alarm_id = id
      @example_alarm_values = values
      return CMAlarmHWRPMockDummyExampleAlarm.new
    end
  end

  # Stupid simple class to mock the Example Alarm response
  class CMAlarmHWRPMockDummyExampleAlarm
    def bound_criteria
      return 'Test Example Alarm Criteria'
    end
  end

  # This is a simple mock of Opscode::Rackspace::Monitoring::CMCheck
  # Testing the behavior, not the implementation, it allows us to return nil or an object
  #  depending on the label passed.
  class CMCheckHWRPMock
    attr_accessor :obj
    attr_writer   :obj

    def initialize(my_credentials, my_entity_label, my_label)
      @init_label = my_label
      @obj = CMCheckHWRPMockCheckObj.new
    end

    def lookup_by_label(label)
      if label != 'Bogus Test Label'
        @obj = CMCheckHWRPMockCheckObj.new
      else
        if label != @init_label
          fail 'CMCheckHWRPMock passed mismatched label: Caller not behaving as expected'
        end

        @obj = nil
      end
    end
  end

  # Stupid simple class to mock the CMCheck Object
  class CMCheckHWRPMockCheckObj
    def id
      return 'Test CMCheck Object ID'
    end
  end
end

#
# WARNING: This namespace is SHARED WITH OTHER TESTS so names MUST BE UNIQUE
#
def initialize_alarm_provider_test
  # Mock CMAlarm with CMAlarmHWRPMock
  stub_const('Opscode::Rackspace::Monitoring::CMAlarm', AlarmHWRPTestMocks::CMAlarmHWRPMock)
  unless Opscode::Rackspace::Monitoring::CMAlarm.new(nil, nil, nil).is_a? AlarmHWRPTestMocks::CMAlarmHWRPMock
    fail 'Failed to stub Opscode::Rackspace::Monitoring::CMAlarm'
  end

  # Mock CMAlarm with CMCheckHWRPMock
  stub_const('Opscode::Rackspace::Monitoring::CMCheck', AlarmHWRPTestMocks::CMCheckHWRPMock)
  unless Opscode::Rackspace::Monitoring::CMCheck.new(nil, nil, nil).is_a? AlarmHWRPTestMocks::CMCheckHWRPMock
    fail 'Failed to stub Opscode::Rackspace::Monitoring::CMCheck'
  end

  @node_data = nil
  @new_resource = TestResourceData.new(
                                       name:  'Test name',
                                       label: 'Test Label',
                                       entity_chef_label:    'Test entity_chef_label',
                                       notification_plan_id: 'Test notification_plan_id',
                                       check_id:    'Test check_id',
                                       check_label: nil,
                                       metadata:    { test: 'Test metadata' },
                                       criteria:    'Test criteria',
                                       disabled:    false,
                                       example_id:  nil,
                                       example_values:     { test: 'Test example_values' },
                                       rackspace_api_key:  'Test rackspace_api_key',
                                       rackspace_username: 'Test rackspace_username',
                                       rackspace_auth_url: 'Test rackspace_auth_url'
                                       )
end

# This method tests the behavior expected by both :create and :create_if_missing when modifying the resource
def common_alarm_update_tests(target_action, alarm_obj_state = nil) # rubocop:disable MethodLength
                                                              # Yea, I know it's long, not really much to be done about it...
                                                              # rspec code is hard to code DRY due to scoping and slight but critical differences...
  def common_update_tests_core(target_action, alarm_obj_state)
    test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.alarm_obj.obj = alarm_obj_state
    test_obj.send(target_action)
    return test_obj
  end

  fail 'ARGUMENT ERROR' if target_action.nil?
  let(:target_action) { target_action }
  let(:alarm_obj_state) { alarm_obj_state }

  it 'fails when notification_plan_id is unset' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.notification_plan_id = nil
    test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.alarm_obj.obj = alarm_obj_state
    expect { test_obj.send(target_action) }.to raise_exception
  end

  it 'fails when both example_id and criteria are set' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.criteria.should_not eql nil
    @new_resource.example_id = 'Test Example ID'
    test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.alarm_obj.obj = alarm_obj_state
    expect { test_obj.send(target_action) }.to raise_exception
  end

  it 'fails when both check_label and check_id are set' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.check_id.should_not eql nil
    @new_resource.check_label = 'Test Check Label'
    test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.alarm_obj.obj = alarm_obj_state
    expect { test_obj.send(target_action) }.to raise_exception
  end

  it 'Uses criteria when example_id is unspecified' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.criteria.should_not eql nil
    @new_resource.example_id.should eql nil
    test_obj = common_update_tests_core(target_action, alarm_obj_state)

    test_obj.current_resource.alarm_obj.example_alarm_id.should eql nil
    test_obj.current_resource.alarm_obj.example_alarm_values.should eql nil
    test_obj.current_resource.alarm_obj.update_args.key?(:criteria).should eql true
    test_obj.current_resource.alarm_obj.update_args[:criteria].should eql @new_resource.criteria
  end

  it 'Uses the example API when example_id is specified' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.criteria = nil
    @new_resource.example_id = 'Test Example ID'
    @new_resource.example_values.should_not eql nil
    test_obj = common_update_tests_core(target_action, alarm_obj_state)

    test_obj.current_resource.alarm_obj.example_alarm_id.should eql @new_resource.example_id
    test_obj.current_resource.alarm_obj.example_alarm_values.should eql @new_resource.example_values
    test_obj.current_resource.alarm_obj.update_args.key?(:criteria).should eql true
    test_obj.current_resource.alarm_obj.update_args[:criteria].should eql 'Test Example Alarm Criteria'
  end

  it 'Uses check_id when check_label is unset' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.check_id.should_not eql nil
    @new_resource.check_label.should eql nil
    test_obj = common_update_tests_core(target_action, alarm_obj_state)

    test_obj.current_resource.alarm_obj.update_args.key?(:check).should eql true
    test_obj.current_resource.alarm_obj.update_args[:check].should eql @new_resource.check_id
  end

  it 'Looks up a check when check_label is set' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.check_id = nil
    @new_resource.check_label = 'Test Check Label'
    test_obj = common_update_tests_core(target_action, alarm_obj_state)

    test_obj.current_resource.alarm_obj.update_args.key?(:check).should eql true
    test_obj.current_resource.alarm_obj.update_args[:check].should eql AlarmHWRPTestMocks::CMCheckHWRPMockCheckObj.new.id
  end

  it 'fails when check_label is set but cannot be looked up' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.check_id = nil
    @new_resource.check_label = 'Bogus Test Label' # This label is coded into the CMCheckHWRPMock mock class below.

    test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.alarm_obj.obj = alarm_obj_state
    expect { test_obj.send(target_action) }.to raise_exception

  end

  [:label, :metadata, :notification_plan_id, :disabled].each do |option|
    it "passes #{option} to update" do
      @new_resource.send(option).should_not eql nil
      test_obj = common_update_tests_core(target_action, alarm_obj_state)

      test_obj.current_resource.alarm_obj.update_args.key?(option).should eql true
      test_obj.current_resource.alarm_obj.update_args[option].should eql @new_resource.send(option)
    end
  end

  it 'notifies Chef that the resource was updated' do
    test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.alarm_obj.obj = alarm_obj_state
    test_obj.new_resource.updated.should eql nil

    test_obj.send(target_action)
    test_obj.new_resource.updated.should eql true
  end
end

describe 'rackspace_cloudmonitoring_alarm' do
  describe 'resource' do
    describe '#initialize' do
      before :each do
        @test_resource = Chef::Resource::RackspaceCloudmonitoringAlarm.new('Test Label')
      end

      it 'should have a resource name of rackspace_cloudmonitoring_alarm' do
        @test_resource.resource_name.should eql :rackspace_cloudmonitoring_alarm
      end

      [:create, :create_if_missing, :delete, :nothing].each do |action|
        it "should support the #{action} action" do
          @test_resource.allowed_actions.should include action
        end
      end

      it 'should should have a default :create action' do
        @test_resource.action.should eql :create
      end

      it 'should set label to the name attribute' do
        @test_resource.label.should eql 'Test Label'
      end
    end

    { label:                'Attr Test Label',
      entity_chef_label:    'Attr Test Entity',
      notification_plan_id: 'Attr Test ID',
      check_id:             'Attr Test Check',
      check_label:          'Attr Test Check Label',
      metadata:             { test: 'Attr metadata' },
      criteria:             'Attr Test Criteria',
      disabled:             true,
      example_id:           'Attr Test Example',
      example_values:       { test: 'Attr example data' },
      rackspace_api_key:    'Attr Test Key',
      rackspace_username:   'Attr Test Username',
      rackspace_auth_url:   'Attr Test Auth URL'
    }.each do |attr, value|
      describe "##{attr}" do
        before :all do
          @test_resource = Chef::Resource::RackspaceCloudmonitoringAlarm.new('Test Label')
        end

        unless [:label, :entity_chef_label].include? attr
          it 'should be nil initially' do
            @test_resource.send(attr).should eql nil
          end
        end

        it 'should set values' do
          @test_resource.send(attr, value).should eql value
        end

        it 'should get values' do
          @test_resource.send(attr).should eql value
        end
      end
    end
  end

  describe 'provider' do
    describe 'load_current_resource' do
      before :each do
        initialize_alarm_provider_test
        # We need all values set for the constructor test
        @new_resource = TestResourceData.new(
                                             name:                 'Test Name',
                                             label:                'Test Label',
                                             entity_chef_label:    'Test Entity',
                                             notification_plan_id: 'Test ID',
                                             check_id:             'Test Check',
                                             check_label:          'Test Check Label',
                                             metadata:             { test: 'metadata' },
                                             criteria:             'Test Criteria',
                                             disabled:             true,
                                             example_id:           'Test Example',
                                             example_values:       { test: 'example data' },
                                             rackspace_api_key:    'Test Key',
                                             rackspace_username:   'Test Username',
                                             rackspace_auth_url:   'Test Auth URL'
                                             )
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudmonitoringAlarm' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudmonitoringAlarm
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @new_resource.label = nil
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.label.should eql 'Test Name'
      end

      it 'Sets label to new_resource.label when new_resource.label is specified' do
        @test_obj.current_resource.label.should eql 'Test Label'
      end

      [:entity_chef_label, :notification_plan_id, :check_id, :check_label, :metadata, :criteria, :disabled,
       :example_id, :example_values, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
        it "Sets #{arg} to new_resource.#{arg}" do
          @new_resource.send(arg).should_not eql nil
          @test_obj.current_resource.send(arg).should eql @new_resource.send(arg)
        end
      end

      it 'passes Opscode::Rackspace::Monitoring::CMAlarm a CMCredentials class, the entity_label, and the label' do
        @test_obj.current_resource.alarm_obj.credentials.should be_an_instance_of Opscode::Rackspace::Monitoring::CMCredentials
        @test_obj.current_resource.alarm_obj.entity_label.should eql 'Test Entity'
        @test_obj.current_resource.alarm_obj.label.should eql 'Test Label'
      end

      it 'Looks up existing alarms by label' do
        @test_obj.current_resource.alarm_obj.lookup_label.should eql 'Test Label'
      end
    end

    describe 'action_create' do
      describe 'with a nil current object' do
        before :each do
          initialize_alarm_provider_test
        end

        common_alarm_update_tests(:action_create, nil)
      end

      describe 'with a non-nil current object' do
        before :each do
          initialize_alarm_provider_test
        end

        common_alarm_update_tests(:action_create, 'not nil')
      end
    end

    describe 'action_create_if_missing' do
      describe 'with a nil current object' do
        before :each do
          initialize_alarm_provider_test
        end

        common_alarm_update_tests(:action_create_if_missing, nil)
      end

      describe 'with a non-nil current object' do
        before :each do
          initialize_alarm_provider_test
        end

        it 'does not call update' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.alarm_obj.obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.current_resource.alarm_obj.update_args.should eql nil
        end

        it 'notifies Chef that the resource was not updated' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.alarm_obj.obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.action_create_if_missing
          test_obj.new_resource.updated.should eql false
        end
      end
    end

    describe 'action_delete' do
      before :each do
        initialize_alarm_provider_test
      end

      it 'calls delete()' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.alarm_obj.delete_called.should eql false
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_delete

        @test_obj.current_resource.alarm_obj.delete_called.should eql true
        @test_obj.new_resource.updated.should eql true
      end
    end

    describe 'action_nothing' do
      before :each do
        # For this test mock Opscode::Rackspace::Monitoring::CMAlarm with an empty class
        # This will cause an exception if methods are accessed
        class DummyClass
        end
        stub_const('Opscode::Rackspace::Monitoring::CMAlarm', DummyClass)

        unless Opscode::Rackspace::Monitoring::CMAlarm.new.is_a? DummyClass
          fail 'Failed to stub Opscode::Rackspace::Monitoring::CMAlarm'
        end

        @node_data = nil
        @new_resource = TestResourceData.new(
                                             name:  'Test name',
                                             label: nil,
                                             entity_chef_label:    'Test entity_chef_label',
                                             notification_plan_id: 'Test notification_plan_id',
                                             check_id:    'Test check_id',
                                             check_label: 'Test check_label',
                                             metadata:    { test: 'Test metadata' },
                                             criteria:    'Test criteria',
                                             disabled:    false,
                                             example_id:  'Test example_id',
                                             example_values:     { test: 'Test example_values' },
                                             rackspace_api_key:  'Test rackspace_api_key',
                                             rackspace_username: 'Test rackspace_username',
                                             rackspace_auth_url: 'Test rackspace_auth_url'
                                            )
      end

      it 'Does nothing' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAlarm.new(@new_resource, nil)
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_nothing
        @test_obj.new_resource.updated.should eql false
      end
    end
  end
end
