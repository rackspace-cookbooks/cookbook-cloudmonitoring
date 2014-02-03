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

require_relative '../../../libraries/check_hwrp.rb'
require_relative 'hwrp_helpers.rb'

module CheckHWRPTestMocks
  # Dog simple mock class to ensure we're calling the underlying class with the right arguments
  # Actual behavior of the underlying classes is tested by their respective tests
  class CMCheckHWRPMock
    attr_accessor :credentials, :obj, :update_args, :delete_called, :entity_label, :label, :lookup_label
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
  end
end

#
# WARNING: This namespace is SHARED WITH OTHER TESTS so names MUST BE UNIQUE
#
def initialize_check_provider_test
  # Mock CMCheck with CMCheckHWRPMock
  stub_const('Opscode::Rackspace::Monitoring::CMCheck', CheckHWRPTestMocks::CMCheckHWRPMock)
  unless Opscode::Rackspace::Monitoring::CMCheck.new(nil, nil, nil).is_a? CheckHWRPTestMocks::CMCheckHWRPMock
    fail 'Failed to stub Opscode::Rackspace::Monitoring::CMCheck'
  end

  @node_data = nil
  @new_resource = TestResourceData.new(
                                       name:  'Test name',
                                       label: 'Test Label',
                                       entity_chef_label: 'Test entity_chef_label',
                                       type:     'Testing Test',
                                       details:  { test: 'Test Details' },
                                       metadata: { test: 'Test metadata' },
                                       period:   42,
                                       timeout:  163,
                                       disabled: false,
                                       target_alias:    'Test Target Alias',
                                       target_resolver: 'Test Target Resolver',
                                       target_hostname: 'Test Target Hostname',
                                       monitoring_zones_poll: ['Test Zone'],
                                       rackspace_api_key:  'Test rackspace_api_key',
                                       rackspace_username: 'Test rackspace_username',
                                       rackspace_auth_url: 'Test rackspace_auth_url'
                                       )
end

# This method tests the behavior expected by both :create and :create_if_missing when modifying the resource
def common_check_update_tests(target_action, check_obj_state = nil)
  fail 'ARGUMENT ERROR' if target_action.nil?
  let(:target_action) { target_action }
  let(:check_obj_state) { check_obj_state }

  [:label, :type, :details, :metadata, :monitoring_zones_poll, :target_alias, :target_hostname, :target_resolver,
   :timeout, :period, :disabled].each do |option|
    it "passes #{option} to update" do
      @new_resource.send(option).should_not eql nil
      test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
      test_obj.load_current_resource
      test_obj.current_resource.check_obj.obj = check_obj_state
      test_obj.send(target_action)

      test_obj.current_resource.check_obj.update_args.key?(option).should eql true
      test_obj.current_resource.check_obj.update_args[option].should eql @new_resource.send(option)
    end
  end

  it 'notifies Chef that the resource was updated' do
    test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.check_obj.obj = check_obj_state
    test_obj.new_resource.updated.should eql nil

    test_obj.send(target_action)
    test_obj.new_resource.updated.should eql true
  end
end

describe 'rackspace_cloudmonitoring_check' do
  describe 'resource' do
    describe '#initialize' do
      before :each do
        @test_resource = Chef::Resource::RackspaceCloudmonitoringCheck.new('Test Label')
      end

      it 'should have a resource name of rackspace_cloudmonitoring_check' do
        @test_resource.resource_name.should eql :rackspace_cloudmonitoring_check
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

    { label: 'Attr Test Label',
      entity_chef_label: 'Attr Test entity_chef_label',
      type:     'Attr Testing Test',
      details:  { test: 'Attr Test Details' },
      metadata: { test: 'Attr Test metadata' },
      period:   256,
      timeout:  512,
      disabled: true,
      target_alias:    'Attr Test Target Alias',
      target_resolver: 'Attr Test Target Resolver',
      target_hostname: 'Attr Test Target Hostname',
      monitoring_zones_poll: ['Attr Test Zone'],
      rackspace_api_key:  'Attr Test rackspace_api_key',
      rackspace_username: 'Attr Test rackspace_username',
      rackspace_auth_url: 'Attr Test rackspace_auth_url'
    }.each do |attr, value|
      describe "##{attr}" do
        before :all do
          @test_resource = Chef::Resource::RackspaceCloudmonitoringCheck.new('Test Label')
        end

        unless [:label, :entity_chef_label, :type].include? attr
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
        initialize_check_provider_test
        @test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudmonitoringCheck' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudmonitoringCheck
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @new_resource.label = nil
        @test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.label.should eql 'Test name'
      end

      it 'Sets label to new_resource.label when new_resource.label is specified' do
        @test_obj.current_resource.label.should eql 'Test Label'
      end

      [:entity_chef_label, :type, :details, :metadata, :period, :timeout, :disabled, :target_alias, :target_resolver,
       :target_hostname, :monitoring_zones_poll, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
        it "Sets #{arg} to new_resource.#{arg}" do
          @new_resource.send(arg).should_not eql nil
          @test_obj.current_resource.send(arg).should eql @new_resource.send(arg)
        end
      end

      it 'passes Opscode::Rackspace::Monitoring::CMCheck a CMCredentials class, the entity_label, and the label' do
        @test_obj.current_resource.check_obj.credentials.should be_an_instance_of Opscode::Rackspace::Monitoring::CMCredentials
        @test_obj.current_resource.check_obj.entity_label.should eql 'Test entity_chef_label'
        @test_obj.current_resource.check_obj.label.should eql 'Test Label'
      end

      it 'Looks up existing checks by label' do
        @test_obj.current_resource.check_obj.lookup_label.should eql 'Test Label'
      end
    end

    describe 'action_create' do
      describe 'with a nil current object' do
        before :each do
          initialize_check_provider_test
        end

        common_check_update_tests(:action_create, nil)
      end

      describe 'with a non-nil current object' do
        before :each do
          initialize_check_provider_test
        end

        common_check_update_tests(:action_create, 'not nil')
      end
    end

    describe 'action_create_if_missing' do
      describe 'with a nil current object' do
        before :each do
          initialize_check_provider_test
        end

        common_check_update_tests(:action_create_if_missing, nil)
      end

      describe 'with a non-nil current object' do
        before :each do
          initialize_check_provider_test
        end

        it 'does not call update' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.check_obj.obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.current_resource.check_obj.update_args.should eql nil
        end

        it 'notifies Chef that the resource was not updated' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.check_obj.obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.action_create_if_missing
          test_obj.new_resource.updated.should eql false
        end
      end
    end

    describe 'action_delete' do
      before :each do
        initialize_check_provider_test
      end

      it 'calls delete()' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.check_obj.delete_called.should eql false
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_delete

        @test_obj.current_resource.check_obj.delete_called.should eql true
        @test_obj.new_resource.updated.should eql true
      end
    end

    describe 'action_nothing' do
      before :each do
        # For this test mock Opscode::Rackspace::Monitoring::CMCheck with an empty class
        # This will cause an exception if methods are accessed
        class DummyClass
        end
        stub_const('Opscode::Rackspace::Monitoring::CMCheck', DummyClass)

        unless Opscode::Rackspace::Monitoring::CMCheck.new.is_a? DummyClass
          fail 'Failed to stub Opscode::Rackspace::Monitoring::CMCheck'
        end

        @node_data = nil
        @new_resource = TestResourceData.new(
                                             name:  'Test name',
                                             label: 'Test Label',
                                             entity_chef_label: 'Test entity_chef_label',
                                             type:     'Testing Test',
                                             details:  { test: 'Test Details' },
                                             metadata: { test: 'Test metadata' },
                                             period:   42,
                                             timeout:  163,
                                             disabled: false,
                                             target_alias:    'Test Target Alias',
                                             target_resolver: 'Test Target Resolver',
                                             target_hostname: 'Test Target Hostname',
                                             monitoring_zones_poll: ['Test Zone'],
                                             rackspace_api_key:  'Test rackspace_api_key',
                                             rackspace_username: 'Test rackspace_username',
                                             rackspace_auth_url: 'Test rackspace_auth_url'
                                             )
      end

      it 'Does nothing' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringCheck.new(@new_resource, nil)
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_nothing
        @test_obj.new_resource.updated.should eql false
      end
    end
  end
end
