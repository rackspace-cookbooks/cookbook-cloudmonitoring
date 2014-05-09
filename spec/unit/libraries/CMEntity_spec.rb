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
require_relative '../../../libraries/CMEntity.rb'

require_relative 'test_helpers.rb'

include Opscode::Rackspace::Monitoring

describe 'CMEntity' do
  describe '#new' do
    describe 'without saved entities' do
      it 'takes two parameters and is a CMEntity object' do
        test_obj = CMEntity.new(test_credentials, 'test label')
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMEntity
        test_obj.entity_obj.should eql nil
      end
    end

    describe 'with a saved entity' do
      before :all do
        @entity = generate_entity(test_credentials, 'Valid Entity')
      end

      it 'loads nil for uncached existing entities' do
        test_obj = CMEntity.new(test_credentials, 'Test Entity Label')
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMEntity
        test_obj.entity_obj.should eql nil
      end

      it 'loads cached entities' do
        # This test is jumping ahead a bit in that it needs to call the lookup method to seed the cache.
        # Seed the cache
        test_obj = CMEntity.new(test_credentials, 'Valid Test Entity Label')
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMEntity
        test_obj.entity_obj.should eql nil
        test_obj.lookup_entity_by_id(@entity.id)
        test_obj.entity_obj.should eql @entity

        # Test cache use in the constructor
        # Note that the cache is a class variable
        test_obj_2 = CMEntity.new(test_credentials, 'Valid Test Entity Label')
        test_obj_2.entity_obj.should eql @entity
      end

      it 'bypasses the cache when use_cache = false' do
        # This test is jumping ahead a bit in that it needs to call the lookup method to seed the cache.
        test_obj = CMEntity.new(test_credentials, 'Valid Test Entity Label', true)
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMEntity
        # Cache already seeded by above test.
        test_obj.entity_obj.should eql @entity

        # Test cache use in the constructor
        # Note that the cache is a class variable
        test_obj_2 = CMEntity.new(test_credentials, 'Valid Test Entity Label', false)
        test_obj_2.entity_obj.should eql nil
        test_obj_2.entity_obj.should_not eql @entity
      end
    end
  end

  describe '#lookup_entity_by_id' do
    it 'returns nil with an invalid id' do
      test_obj = CMEntity.new(test_credentials, 'test label')
      test_obj.entity_obj.should eql nil
      test_obj.lookup_entity_by_id('bogus id')
      test_obj.entity_obj.should eql nil
    end

    it 'returns an object with a valid id' do
      entity = generate_entity(test_credentials, 'Valid Entity')
      test_obj = CMEntity.new(test_credentials, 'lookup_entity_by_id() Test Entity Label')
      test_obj.entity_obj.should eql nil
      test_obj.lookup_entity_by_id(entity.id)
      test_obj.entity_obj.should eql entity
    end
  end

  describe '#lookup_entity_by_label' do
    it 'returns nil with an invalid label' do
      test_obj = CMEntity.new(test_credentials, 'test label')
      test_obj.entity_obj.should eql nil
      test_obj.lookup_entity_by_label('bogus label')
      test_obj.entity_obj.should eql nil
    end

    it 'returns an object with a valid label' do
      entity = generate_entity(test_credentials, 'Valid Entity')
      test_obj = CMEntity.new(test_credentials, 'lookup_entity_by_label() Test Entity Label')
      test_obj.entity_obj.should eql nil
      test_obj.lookup_entity_by_label(entity.label)
      test_obj.entity_obj.should eql entity
    end
  end

  describe '#lookup_entity_by_ip' do
    it 'returns nil with an invalid ip' do
      test_obj = CMEntity.new(test_credentials, 'test label')
      test_obj.entity_obj.should eql nil
      test_obj.lookup_entity_by_label('1.2.3.4')
      test_obj.entity_obj.should eql nil
    end

    it 'returns an object with a valid label' do
      entity = generate_entity(test_credentials, 'Valid Entity')
      entity.ip_addresses = { 'foo ip'  => '5.6.7.8' }
      test_obj = CMEntity.new(test_credentials, 'lookup_entity_by_ip() Test Entity Label')
      test_obj.entity_obj.should eql nil
      test_obj.lookup_entity_by_ip('5.6.7.8')
      test_obj.entity_obj.should eql entity
    end
  end

  describe '#to_s' do
    it 'returns a string when the object is nil' do
      test_obj = CMEntity.new(test_credentials, 'test label')
      test_obj.entity_obj.should eql nil
      test_obj.to_s.should be_an_instance_of String
    end

    it 'returns a string when the object not nil' do
      entity = generate_entity(test_credentials, 'Valid Entity')
      test_obj = CMEntity.new(test_credentials, 'Valid Test Entity Label')
      test_obj.lookup_entity_by_id(entity.id)
      test_obj.entity_obj.should_not eql nil
      test_obj.to_s.should be_an_instance_of String
    end
  end

  describe '#update_entity' do
    it 'creates a new object when the current object is nil' do
      test_obj = CMEntity.new(test_credentials, 'update_entity test label')
      test_obj.entity_obj.should eql nil
      test_obj.update_entity('label' => 'Update Test 1').should eql true
      test_obj.entity_obj.should_not eql nil
      test_obj.entity_obj.label.should eql 'Update Test 1'
    end

    it 'updates an existing entity when the current object is not nil' do
      test_obj = CMEntity.new(test_credentials, 'update_entity test label')
      test_obj.entity_obj.should_not eql nil
      orig_id = test_obj.entity_obj.id
      orig_id.should_not eql nil

      test_obj.update_entity('label' => 'Update Test 2').should eql true
      test_obj.entity_obj.should_not eql nil
      test_obj.entity_obj.label.should eql 'Update Test 2'
      test_obj.entity_obj.id.should eql orig_id
    end

    it 'does not update the object when nothing is changed' do
      test_obj = CMEntity.new(test_credentials, 'update_entity test label')
      test_obj.entity_obj.should_not eql nil
      test_obj.entity_obj.label.should eql 'Update Test 2'
      orig_obj = test_obj.entity_obj.dup

      test_obj.update_entity('label' => 'Update Test 2').should eql false
      test_obj.entity_obj.compare?(orig_obj).should eql true
    end

    # https://github.com/rackspace-cookbooks/rackspace_cloudmonitoring/issues/31
    it 'does not create duplicate objects when the API paginates' do
      # Create multiple pages of results: 3xAPI_Max
      test_obj = nil # test_obj must be initialized here or else it will only exist in loop scope
      3000.times do |c|
        test_obj = CMEntity.new(test_credentials, "update_entity pagination test entity #{c}")
        test_obj.update_entity.should eql true
        test_obj.entity_obj_id.should_not eql nil
      end

      # Verify a subsequent update doesn't create a new entry
      # Test the last object
      test_obj2 = CMEntity.new(test_credentials, test_obj.chef_label, false)
      # As we bypassed the cache we need to lookup the entity
      test_obj2.lookup_entity_by_id(test_obj.entity_obj_id)
      test_obj2.entity_obj_id.should eql test_obj.entity_obj_id
      test_obj2.update_entity.should eql false
    end
  end

  describe '#delete_entity' do
    it 'deletes the entity when the current object is not nil' do
      test_obj = CMEntity.new(test_credentials, 'Delete Test')
      test_obj.update_entity('label' => 'Delete Test')
      test_obj.entity_obj.should_not eql nil

      test_obj.delete_entity.should eql true
      test_obj.entity_obj.should eql nil

      # Verify the token was actually deleted by looking it up again
      test_obj = CMEntity.new(test_credentials, 'Delete Test')
      test_obj.entity_obj.should eql nil
    end

    it 'returns false when the current object is nil' do
      test_obj = CMEntity.new(test_credentials, 'Delete Test')
      test_obj.entity_obj.should eql nil
      test_obj.delete_entity.should eql false
    end
  end
end
