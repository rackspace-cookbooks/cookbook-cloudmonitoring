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

require_relative '../../../libraries/agent_token_hwrp.rb'
require_relative 'hwrp_helpers.rb'

module AgentTokenHWRPTestMocks
  # Dog simple mock class to ensure we're calling the underlying class with the right arguments
  # Actual behavior of the underlying classes is tested by their respective tests
  class CMAgentTokenHWRPMock
    attr_accessor :label, :token, :credentials, :obj, :update_args, :delete_called
    attr_writer   :obj

    def initialize(my_credentials, my_token, my_label)
      @credentials = my_credentials
      @token = my_token
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
  end
end

#
# WARNING: This namespace is SHARED WITH OTHER TESTS so names MUST BE UNIQUE
#
def initialize_agent_token_provider_test
  # Mock CMAgentToken with CMAgentTokenHWRPMock
  stub_const('Opscode::Rackspace::Monitoring::CMAgentToken', AgentTokenHWRPTestMocks::CMAgentTokenHWRPMock)

  unless Opscode::Rackspace::Monitoring::CMAgentToken.new(nil, nil, nil).is_a? AgentTokenHWRPTestMocks::CMAgentTokenHWRPMock
    fail 'Failed to stub Opscode::Rackspace::Monitoring::CMAgentToken'
  end

  @node_data = nil
  @new_resource = TestResourceData.new(
                                       name:  'Test name',
                                       label: nil,
                                       token: 'Test token',
                                       rackspace_api_key:  'Test rackspace_api_key',
                                       rackspace_username: 'Test rackspace_username',
                                       rackspace_auth_url: 'Test rackspace_auth_url'
                                       )
end

describe 'rackspace_cloudmonitoring_agent_token' do
  describe 'resource' do
    describe '#initialize' do
      before :each do
        @test_resource = Chef::Resource::RackspaceCloudmonitoringAgentToken.new('Test Label')
      end

      it 'should have a resource name of rackspace_cloudmonitoring_agent_token' do
        @test_resource.resource_name.should eql :rackspace_cloudmonitoring_agent_token
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

    [:label, :token, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |attr|
      describe "##{attr}" do
        before :all do
          @test_resource = Chef::Resource::RackspaceCloudmonitoringAgentToken.new('Test Label')
        end

        if attr != :label
          it 'should be nil initially' do
            @test_resource.send(attr).should eql nil
          end
        end

        it 'should set values' do
          @test_resource.send(attr, 'Testing Value').should eql 'Testing Value'
        end

        it 'should get values' do
          @test_resource.send(attr).should eql 'Testing Value'
        end
      end
    end
  end

  describe 'provider' do
    describe 'load_current_resource' do
      before :each do
        initialize_agent_token_provider_test
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudmonitoringAgentToken' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudmonitoringAgentToken
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @test_obj.current_resource.label.should eql 'Test name'
      end

      it 'Sets label to new_resource.label when new_resource.label is specified' do
        @new_resource.label = 'Test Label'
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.label.should eql 'Test Label'
      end

      [:token, :rackspace_api_key, :rackspace_username, :rackspace_auth_url].each do |arg|
        it "Sets #{arg} to new_resource.#{arg}" do
          @new_resource.send(arg).should_not eql nil
          @test_obj.current_resource.send(arg).should eql "Test #{arg}"
        end
      end

      it 'initializes current_resource.token_obj to be a Opscode::Rackspace::Monitoring::CMAgentToken (Stubbed)' do
        @test_obj.current_resource.token_obj.should be_an_instance_of AgentTokenHWRPTestMocks::CMAgentTokenHWRPMock
      end

      it 'passes Opscode::Rackspace::Monitoring::CMAgentToken a CMCredentials class, the token, and the label' do
        @test_obj.current_resource.token_obj.credentials.should be_an_instance_of Opscode::Rackspace::Monitoring::CMCredentials
        @test_obj.current_resource.token_obj.token.should eql 'Test token'
        @test_obj.current_resource.token_obj.label.should eql 'Test name'
      end
    end

    describe 'action_create' do
      before :each do
        initialize_agent_token_provider_test
      end

      it 'calls update(label) when the current object is nil' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.token_obj.obj = nil
        @test_obj.current_resource.token_obj.update_args.should eql nil
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_create

        v = { label: 'Test name' }
        @test_obj.current_resource.token_obj.update_args.should eql v
        @test_obj.new_resource.updated.should eql true
      end

      it 'calls update(label) when the current object is not nil' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.token_obj.obj = 'sldfjsdlkfjsdlfj'
        @test_obj.current_resource.token_obj.update_args.should eql nil
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_create

        v = { label: 'Test name' }
        @test_obj.current_resource.token_obj.update_args.should eql v
        @test_obj.new_resource.updated.should eql true
      end
    end

    describe 'action_create_if_missing' do
      before :each do
        initialize_agent_token_provider_test
      end

      it 'calls update(label) when the current object is nil' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.token_obj.obj = nil
        @test_obj.current_resource.token_obj.update_args.should eql nil
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_create_if_missing

        v = { label: 'Test name' }
        @test_obj.current_resource.token_obj.update_args.should eql v
        @test_obj.new_resource.updated.should eql true
      end

      it 'calls update(label) when the current object is not nil' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.token_obj.obj = 'sldfjsdlkfjsdlfj'
        @test_obj.current_resource.token_obj.update_args.should eql nil
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_create_if_missing

        @test_obj.current_resource.token_obj.update_args.should eql nil
        @test_obj.new_resource.updated.should eql false
      end
    end

    describe 'action_delete' do
      before :each do
        initialize_agent_token_provider_test
      end

      it 'calls delete()' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.token_obj.delete_called.should eql false
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_delete

        @test_obj.current_resource.token_obj.delete_called.should eql true
        @test_obj.new_resource.updated.should eql true
      end
    end

    describe 'action_nothing' do
      before :each do
        # For this test mock Opscode::Rackspace::Monitoring::CMAgentToken with an empty class
        # This will cause an exception if methods are accessed
        class DummyClass
        end
        stub_const('Opscode::Rackspace::Monitoring::CMAgentToken', DummyClass)

        unless Opscode::Rackspace::Monitoring::CMAgentToken.new.is_a? DummyClass
          fail 'Failed to stub Opscode::Rackspace::Monitoring::CMAgentToken'
        end

        @node_data = nil
        @new_resource = TestResourceData.new(
                                            name:  'Test name',
                                            label: nil,
                                            token: 'Test token',
                                            rackspace_api_key:  'Test rackspace_api_key',
                                            rackspace_username: 'Test rackspace_username',
                                            rackspace_auth_url: 'Test rackspace_auth_url'
                                            )
      end

      it 'Does nothing' do
        @test_obj = Chef::Provider::RackspaceCloudmonitoringAgentToken.new(@new_resource, nil)
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_nothing
        @test_obj.new_resource.updated.should eql false
      end
    end

  end
end
