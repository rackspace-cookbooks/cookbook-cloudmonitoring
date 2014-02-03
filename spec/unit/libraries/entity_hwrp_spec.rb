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

require_relative '../../../libraries/entity_hwrp.rb'
require_relative 'hwrp_helpers.rb'

module EntityHWRPTestMocks
  # Dog simple mock class to ensure we're calling the underlying class with the right arguments
  # Actual behavior of the underlying classes is tested by their respective tests
  class CMEntityHWRPMock
    attr_accessor :credentials, :entity_obj, :update_args, :delete_called, :label, :lookup_label, :lookup_ip, :lookup_id
    attr_writer   :entity_obj

    def initialize(my_credentials, my_label)
      @credentials = my_credentials
      @label = my_label
      @delete_called = false
    end

    def update_entity(args = {})
      @update_args = args
      return true
    end

    def delete_entity
      @delete_called = true
      return true
    end
                                      # We're mocking here, and attr_writer doesn't behave the same
    def lookup_entity_by_label(label) # rubocop:disable TrivialAccessors
      @lookup_label = label
    end

    def lookup_entity_by_ip(label) # rubocop:disable TrivialAccessors
      @lookup_ip = label
    end

    def lookup_entity_by_id(label) # rubocop:disable TrivialAccessors
      @lookup_id = label
    end
  end
end

#
# WARNING: This namespace is SHARED WITH OTHER TESTS so names MUST BE UNIQUE
#
def initialize_entity_provider_test
  # Mock CMEntity with CMEntityHWRPMock
  stub_const('Opscode::Rackspace::Monitoring::CMEntity', EntityHWRPTestMocks::CMEntityHWRPMock)
  unless Opscode::Rackspace::Monitoring::CMEntity.new(nil, nil).is_a? EntityHWRPTestMocks::CMEntityHWRPMock
    fail 'Failed to stub Opscode::Rackspace::Monitoring::CMEntity'
  end

  @node_data = nil
  @new_resource = TestResourceData.new(
                                       name:          'Test name',
                                       label:         'Test Label',
                                       api_label:     'Test api_label',
                                       metadata:      { test: 'Test metadata' },
                                       ip_addresses:  { test: '1.2.3.4' },
                                       agent_id:      'Test agent_id',
                                       search_method: 'Test search_method',
                                       search_ip:     'Test search_ip',
                                       search_id:     'Test search_id',
                                       rackspace_api_key:  'Test rackspace_api_key',
                                       rackspace_username: 'Test rackspace_username',
                                       rackspace_auth_url: 'Test rackspace_auth_url'
                                       )
end

def common_entity_update_tests_core(target_action, entity_obj_state)
  test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
  test_obj.load_current_resource
  test_obj.current_resource.entity_obj.entity_obj = entity_obj_state
  test_obj.send(target_action)
  return test_obj
end

# This method tests the behavior expected by both :create and :create_if_missing when modifying the resource
def common_entity_create_tests(target_action, entity_obj_state = nil) # rubocop:disable MethodLength
                                                                      # Yea, I know it's long, not really much to be done about it...
                                                                      # rspec code is hard to code DRY due to scoping and slight but critical differences...

  fail 'ARGUMENT ERROR' if target_action.nil?
  let(:target_action) { target_action }
  let(:entity_obj_state) { entity_obj_state }

  it 'fails when ip_addresses is omitted but search_method is \'ip\'' do
    fail 'SCOPE ERROR' if target_action.nil?
    @new_resource.ip_addresses = nil
    @new_resource.search_method = 'ip'
    test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.entity_obj.entity_obj = entity_obj_state
    expect { test_obj.send(target_action) }.to raise_exception
  end

  [:ip_addresses, :metadata, :agent_id].each do |option|
    it "passes #{option} to update" do
      @new_resource.send(option).should_not eql nil
      test_obj = common_entity_update_tests_core(target_action, entity_obj_state)

      test_obj.current_resource.entity_obj.update_args.key?(option).should eql true
      test_obj.current_resource.entity_obj.update_args[option].should eql @new_resource.send(option)
    end
  end

  it 'passes api_label to update as the label when api_label is specified' do
    @new_resource.api_label.should_not eql nil
    @new_resource.api_label.should_not eql @new_resource.label
    test_obj = common_entity_update_tests_core(target_action, entity_obj_state)

    test_obj.current_resource.entity_obj.update_args.key?(:label).should eql true
    test_obj.current_resource.entity_obj.update_args[:label].should eql @new_resource.api_label
  end

  it 'passes label to update when api_label is nil' do
    @new_resource.label.should_not eql nil
    @new_resource.api_label = nil
    test_obj = common_entity_update_tests_core(target_action, entity_obj_state)

    test_obj.current_resource.entity_obj.update_args.key?(:label).should eql true
    test_obj.current_resource.entity_obj.update_args[:label].should eql @new_resource.label
  end

  it 'notifies Chef that the resource was updated' do
    test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
    test_obj.load_current_resource
    test_obj.current_resource.entity_obj.entity_obj = entity_obj_state
    test_obj.new_resource.updated.should eql nil

    test_obj.send(target_action)
    test_obj.new_resource.updated.should eql true
  end
end

describe 'rackspace_cloudmonitoring_entity' do
  describe 'resource' do
    describe '#initialize' do
      before :each do
        @test_resource = Chef::Resource::RackspaceCloudmonitoringEntity.new('Test Label')
      end

      it 'should have a resource name of rackspace_cloudmonitoring_entity' do
        @test_resource.resource_name.should eql :rackspace_cloudmonitoring_entity
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
      api_label:            'Attr Test api_label',
      metadata:             { test: 'Attr Test metadata' },
      ip_addresses:         { test: 'Attr Test ip_addresses' },
      agent_id:             'Attr Test agent_id',
      search_method:        'Attr Test search_method',
      search_ip:            'Attr Test search_ip',
      search_id:            'Attr Test search_id',
      rackspace_api_key:    'Attr Test Key',
      rackspace_username:   'Attr Test Username',
      rackspace_auth_url:   'Attr Test Auth URL'
    }.each do |attr, value|
      describe "##{attr}" do
        before :all do
          @test_resource = Chef::Resource::RackspaceCloudmonitoringEntity.new('Test Label')
        end

        unless [:label, :entity_chef_label, :notification_plan_id].include? attr
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
        initialize_entity_provider_test
        @test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudmonitoringEntity' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudmonitoringEntity
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @new_resource.label = nil
        @test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.label.should eql 'Test name'
      end

      it 'Sets label to new_resource.label when new_resource.label is specified' do
        @test_obj.current_resource.label.should eql 'Test Label'
      end

      [:api_label, :metadata, :ip_addresses, :agent_id, :search_method, :search_ip,
       :search_id, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
        it "Sets #{arg} to new_resource.#{arg}" do
          @new_resource.send(arg).should_not eql nil
          @test_obj.current_resource.send(arg).should eql @new_resource.send(arg)
        end
      end

      it 'passes Opscode::Rackspace::Monitoring::CMEntity a CMCredentials class, the entity_label, and the label' do
        @test_obj.current_resource.entity_obj.credentials.should be_an_instance_of Opscode::Rackspace::Monitoring::CMCredentials
        @test_obj.current_resource.entity_obj.label.should eql 'Test Label'
      end

      searches = { 'IP' =>               { getter: :lookup_ip,    value_getter: :search_ip, method: 'ip' },
                   'ID' =>               { getter: :lookup_id,    value_getter: :search_id, method: 'id' },
                   'API Label' =>        { getter: :lookup_label, value_getter: :api_label, method: 'api_label' },
                   'Label' =>            { getter: :lookup_label, value_getter: :label,     method: 'label' },
                   'Label (Default)' => { getter: :lookup_label, value_getter: :label,     method: nil }
      }

      searches.each do |title, test_data|
        it "looks up existing entities by #{title}" do
          @new_resource.search_method = test_data[:method]
          @new_resource.send(test_data[:value_getter]).should_not eql nil
          @test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
          @test_obj.load_current_resource
          @test_obj.current_resource.entity_obj.send(test_data[:getter]).should eql @new_resource.send(test_data[:value_getter])

          # Check that other lookups were not called
          [:lookup_ip, :lookup_id, :lookup_label].each do |getter|
            unless getter == test_data[:getter]
              @test_obj.current_resource.entity_obj.send(getter).should eql nil
            end
          end
        end
      end

      ['IP', 'ID', 'API Label'].each do |title|
        test_data = searches[title]
        it "errors if the #{title} search parameter is nil" do
          @new_resource.search_method = test_data[:method]
          @new_resource.send("#{test_data[:value_getter]}=", nil)
          @test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
          expect { @test_obj.load_current_resource }.to raise_error
        end
      end
    end

    describe 'action_create' do
      describe 'with a nil current object' do
        before :each do
          initialize_entity_provider_test
        end

        common_entity_create_tests(:action_create, nil)
      end

      describe 'with a non-nil current object' do
        before :each do
          initialize_entity_provider_test
        end

        [:metadata, :agent_id].each do |option|
          it "passes #{option} to update" do
            @new_resource.send(option).should_not eql nil
            test_obj = common_entity_update_tests_core(:action_create, 'not nil')

            test_obj.current_resource.entity_obj.update_args.key?(option).should eql true
            test_obj.current_resource.entity_obj.update_args[option].should eql @new_resource.send(option)
          end
        end

        [:label, :ip_addresses].each do |option|
          it "does not pass #{option} to update" do
            @new_resource.send(option).should_not eql nil
            test_obj = common_entity_update_tests_core(:action_create, 'not nil')

            test_obj.current_resource.entity_obj.update_args.key?(option).should eql false
          end
        end

        it 'notifies Chef that the resource was updated' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.entity_obj.entity_obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.action_create
          test_obj.new_resource.updated.should eql true
        end
      end
    end

    describe 'action_create_if_missing' do
      describe 'with a nil current object' do
        before :each do
          initialize_entity_provider_test
        end

        common_entity_create_tests(:action_create_if_missing, nil)
      end

      describe 'with a non-nil current object' do
        before :each do
          initialize_entity_provider_test
        end

        it 'does not call update' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.entity_obj.entity_obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.current_resource.entity_obj.update_args.should eql nil
        end

        it 'notifies Chef that the resource was not updated' do
          test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
          test_obj.load_current_resource
          test_obj.current_resource.entity_obj.entity_obj = 'not nil'
          test_obj.new_resource.updated.should eql nil

          test_obj.action_create_if_missing
          test_obj.new_resource.updated.should eql false
        end
      end
    end

    describe 'action_delete' do
      before :each do
        initialize_entity_provider_test
      end

      it 'calls delete()' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.entity_obj.delete_called.should eql false
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_delete

        @test_obj.current_resource.entity_obj.delete_called.should eql true
        @test_obj.new_resource.updated.should eql true
      end
    end

    describe 'action_nothing' do
      before :each do
        # For this test mock Opscode::Rackspace::Monitoring::CMEntity with an empty class
        # This will cause an exception if methods are accessed
        class DummyClass
        end
        stub_const('Opscode::Rackspace::Monitoring::CMEntity', DummyClass)

        unless Opscode::Rackspace::Monitoring::CMEntity.new.is_a? DummyClass
          fail 'Failed to stub Opscode::Rackspace::Monitoring::CMEntity'
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
        @test_obj = Chef::Provider::RackspaceCloudmonitoringEntity.new(@new_resource, nil)
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_nothing
        @test_obj.new_resource.updated.should eql false
      end
    end
  end
end
