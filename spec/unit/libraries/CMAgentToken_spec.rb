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

require_relative '../../../libraries/CMAgentToken.rb'
require_relative '../../../libraries/CMCredentials.rb'
require_relative '../../../libraries/CMApi.rb'
include Opscode::Rackspace::Monitoring

def generate_token(credentials, label)
  fail 'ERROR: nil credentials' if credentials.nil?
  cm = CMApi.new(credentials).cm
  token = cm.agent_tokens.new
  token.label = label
  token.save
  return token
end

def test_credentials
  return CMCredentials.new({
                             'rackspace_cloudmonitoring' => { 'mock' => true },
                             'rackspace' => { 'cloud_credentials' => {
                                 'username' => 'Mr. Mockson',
                                 'api_key'  => 'Woodruff'
                               } }
                           }, nil)
end

describe 'CMAgentToken' do
  describe '#new' do
    describe 'without saved tokens' do
      it 'takes three parameters and is a CMAgentToken object' do
        agent_token_obj = CMAgentToken.new(test_credentials, 'test token', 'test label')
        agent_token_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMAgentToken
        agent_token_obj.obj.should eql nil
      end

      it 'rejects a nil label with a bad token' do
        expect { CMAgentToken.new(test_credentials, 'bad token', nil) }.to raise_exception
      end

      it 'rejects a nil label without a token' do
        expect { CMAgentToken.new(test_credentials, nil, nil) }.to raise_exception
      end
    end

    describe 'with a saved token' do
      before :all do
        # Generate a token
        @token = generate_token(test_credentials, 'Testing Label')
      end

      it 'uses existing tokens by id' do
        agent_token_obj = CMAgentToken.new(test_credentials, @token.id, nil)
        agent_token_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMAgentToken
        agent_token_obj.obj.should eql @token
      end

      it 'uses existing tokens by label' do
        agent_token_obj = CMAgentToken.new(test_credentials, nil, @token.label)
        agent_token_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMAgentToken
        agent_token_obj.obj.should eql @token
      end
    end
  end

  describe '#to_s' do
    it 'returns a string when the object is nil' do
      agent_token_obj = CMAgentToken.new(test_credentials, 'test token', 'test label')
      agent_token_obj.obj.should eql nil
      agent_token_obj.to_s.should be_an_instance_of String
    end

    it 'returns a string when the object not nil' do
      agent_token_obj = CMAgentToken.new(test_credentials, nil, 'Testing Label')
      agent_token_obj.obj.should_not eql nil
      agent_token_obj.to_s.should be_an_instance_of String
    end
  end

  describe '#update' do
    it 'creates a new object when the current object is nil' do
      agent_token_obj = CMAgentToken.new(test_credentials, 'test token', 'test label')
      agent_token_obj.obj.should eql nil
      agent_token_obj.update('label' => 'Update Test 1').should eql true
      agent_token_obj.obj.should_not eql nil
      agent_token_obj.obj.label.should eql 'Update Test 1'
    end

    it 'updates an existing entity when the current object is not nil' do
      agent_token_obj = CMAgentToken.new(test_credentials, nil, 'Update Test 1')
      agent_token_obj.obj.should_not eql nil
      orig_id = agent_token_obj.obj.id
      orig_id.should_not eql nil

      agent_token_obj.update('label' => 'Update Test 2').should eql true
      agent_token_obj.obj.should_not eql nil
      agent_token_obj.obj.label.should eql 'Update Test 2'
      agent_token_obj.obj.id.should eql orig_id
    end

    it 'does not update the object when nothing is changed' do
      agent_token_obj = CMAgentToken.new(test_credentials, nil, 'Update Test 2')
      agent_token_obj.obj.should_not eql nil
      orig_obj = agent_token_obj.obj.dup

      agent_token_obj.update('label' => 'Update Test 2').should eql false
      agent_token_obj.obj.compare?(orig_obj).should eql true
    end
  end

  describe '#delete' do
    it 'deletes the token when the current object is not nil' do
      agent_token_obj = CMAgentToken.new(test_credentials, nil, 'Update Test 2')
      agent_token_obj.obj.should_not eql nil

      agent_token_obj.delete.should eql true
      agent_token_obj.obj.should eql nil

      # Verify the token was actually deleted by looking it up again
      agent_token_obj = CMAgentToken.new(test_credentials, nil, 'Update Test 2')
      agent_token_obj.obj.should eql nil
    end

    it 'returns false when the current object is nil' do
      agent_token_obj = CMAgentToken.new(test_credentials, nil, 'Update Test 2')
      agent_token_obj.obj.should eql nil
      agent_token_obj.delete.should eql false
    end
  end
end
