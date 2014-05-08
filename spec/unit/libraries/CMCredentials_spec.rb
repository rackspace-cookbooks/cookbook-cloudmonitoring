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

require_relative '../../../libraries/CMCredentials.rb'
include Opscode::Rackspace::Monitoring

#
# Set up dummy data for testing
#

# A dummy class to fake resource variables
class LoadedDummyResource
  def rackspace_api_key
    return 'resource apikey'
  end

  def rackspace_username
    return 'resource username'
  end

  def rackspace_auth_url
    return 'resource authurl'
  end

  def monitoring_agent_token
    return 'resource token'
  end

  def monitoring_mock_api
    return 'resource mocking'
  end
end

# An empty class to fake no resource variables
class EmptyDummyResource
end

# A static class to define the test data
# Defined as a class to avoid scoping issues
class TestData
  # Node data: Dummy node data
  # Set only_databag to true to test databags without any other node attributes
  def self.node_data(only_databag = false)
    # Per https://github.com/rackspace-cookbooks/contributing/blob/master/CONTRIBUTING.md
    # use strings for hash keys (:key != 'key')
    data = {
      'rackspace_cloudmonitoring' => {
        'auth' => {
          'databag' => {
            'name' => 'rackspace',
            'item' => 'cloud'
          }
        }
      }
    }

    unless only_databag
      data['rackspace'] = {
        'cloud_credentials' => {
          'username' => 'node username',
          'api_key'  => 'node apikey'
        }
      }
      data['rackspace_cloudmonitoring']['auth']['url'] = 'node authurl'
      data['rackspace_cloudmonitoring']['config'] = { 'agent' => { 'token' => 'node token' } }
      data['rackspace_cloudmonitoring']['mock'] = 'node mocking'
      data['rackspace_cloudmonitoring']['api'] = { 'pagination_limit' => 'node pagination_limit' }
    end

    return data
  end

  # iteration_data: A hash to be looped over to test the various attributes handled
  def self.iteration_data
    return {
      api_key: {
        name: 'apikey',
        resource_supported: true,
        node_supported: true,
        databag_supported: true
      },
      username: {
        name: 'username',
        resource_supported: true,
        node_supported: true,
        databag_supported: true
      },
      auth_url: {
        name: 'authurl',
        resource_supported: true,
        node_supported: true,
        databag_supported: true
      },
      token: {
        name: 'token',
        resource_supported: true,
        node_supported: true,
        databag_supported: true
      },
      mocking: {
        name: 'mocking',
        resource_supported: true,
        node_supported: true,
        databag_supported: false
      },
      pagination_limit: {
        name: 'pagination_limit',
        resource_supported: false,
        node_supported: true,
        databag_supported: false
      }
    }
  end

  # Databag data: Dummy data to be returned from the databag
  def self.databag_data
    return {
      apikey:      'databag apikey',
      username:    'databag username',
      auth_url:    'databag authurl',
      agent_token: 'databag token'
    }
  end

  # stub_databag: Stub out Chef::EncryptedDataBagItem for testing
  # This must be called before each test, it does not behave as expected when called before :all
  def self.stub_databag(data_available)
    if data_available
      Chef::EncryptedDataBagItem.stub(:load).with('rackspace', 'cloud').and_return(TestData.databag_data)
    else
      Chef::EncryptedDataBagItem.stub(:load).with('rackspace', 'cloud').and_return({})
    end
  end
end

#
# Tests
#

describe CMCredentials do
  describe '#new' do
    it 'takes two parameters and is a CMCredentials object' do
      test_creds = CMCredentials.new(nil, LoadedDummyResource.new)
      test_creds.should be_an_instance_of CMCredentials
    end
  end

  describe '#load_databag' do
    before :each do
      TestData.stub_databag(true)
      @test_creds = CMCredentials.new(TestData.node_data, LoadedDummyResource.new)
    end

    it '(SANITY) has good data to work with' do
      Chef::EncryptedDataBagItem.load('rackspace', 'cloud').should eql TestData.databag_data
    end

    it 'returns a hash' do
      @test_creds.load_databag.should be_an_instance_of Hash
    end

    it 'returns databag data' do
      @test_creds.load_databag.should eql TestData.databag_data
    end

    it 'returns empty hash with no databag data' do
      TestData.stub_databag(false)
      @test_creds.load_databag.should == {}
    end
  end

  TestData.iteration_data.each do |key, data|
    describe "#_get_resource_attribute(#{key})" do
      before :each do
        TestData.stub_databag(true)
      end

      if data[:resource_supported]
        it 'returns available resource data' do
          test_creds = CMCredentials.new(nil, LoadedDummyResource.new)
          test_creds._get_resource_attribute(key).should eql "resource #{data[:name]}"
        end
      end

      it 'returns nil for unavailable data' do
        test_creds = CMCredentials.new(nil, EmptyDummyResource.new)
        test_creds._get_resource_attribute(key).should eql nil
      end

      describe "#_get_node_attribute(#{key})" do
        before :each do
          TestData.stub_databag(true)
          @test_node_data = TestData.node_data
        end

        if data[:node_supported]
          it 'returns available node data' do
            test_creds = CMCredentials.new(@test_node_data, LoadedDummyResource.new)
            test_creds._get_node_attribute(key).should eql "node #{data[:name]}"
          end
        end

        it 'returns nil for unavailable data' do
          test_creds = CMCredentials.new(nil, EmptyDummyResource.new)
          test_creds._get_node_attribute(key).should eql nil
        end
      end
    end

    describe "#_get_databag_attribute(#{key})" do
      before :each do
        TestData.stub_databag(true)
        @test_node_data = TestData.node_data
      end

      it 'returns nil without databag credentials' do
        test_creds = CMCredentials.new(nil, LoadedDummyResource.new)
        test_creds._get_databag_attribute(key).should eql nil
      end

      if data[:databag_supported]
        it 'returns available databag data' do
          TestData.stub_databag(true)
          test_creds = CMCredentials.new(@test_node_data, LoadedDummyResource.new)
          test_creds._get_databag_attribute(key).should eql "databag #{data[:name]}"
        end
      end

      it 'returns nil for unavailable data' do
        TestData.stub_databag(false)
        test_creds = CMCredentials.new(@test_node_data, EmptyDummyResource.new)
        test_creds._get_databag_attribute(key).should eql nil
      end
    end

    describe "#get_attributes(#{key})" do
      before :all do
        @test_node_data = TestData.node_data
      end

      before :each do
        TestData.stub_databag(true)
      end

      it '(SANITY) has good data to work with' do
        @test_node_data.should be_an_instance_of Hash
      end

      if data[:resource_supported]
        it 'favors resource attributes over all others' do
          test_creds = CMCredentials.new(@test_node_data, LoadedDummyResource.new)
          test_creds.get_attribute(key).should eql "resource #{data[:name]}"
        end
      end

      if data[:node_supported]
        it 'favors node attributes over databag with an empty resource' do
          test_creds = CMCredentials.new(@test_node_data, EmptyDummyResource.new)
          test_creds.get_attribute(key).should eql "node #{data[:name]}"
        end

        it 'favors node attributes over databag with a nil resource' do
          test_creds = CMCredentials.new(@test_node_data, nil)
          test_creds.get_attribute(key).should eql "node #{data[:name]}"
        end
      end

      if data[:databag_supported]
        it 'Returns databag attributes with no node or resource valuess' do
          test_creds = CMCredentials.new(TestData.node_data(true), nil)
          test_creds.get_attribute(key).should eql "databag #{data[:name]}"
        end
      end

      it 'Returns nil with nothing available' do
        TestData.stub_databag(false)
        test_creds = CMCredentials.new(nil, nil)
        test_creds.get_attribute(key).should eql nil
      end

      it 'Does not modify the node data hash' do
        @test_node_data.should eql TestData.node_data
      end
    end
  end
end
