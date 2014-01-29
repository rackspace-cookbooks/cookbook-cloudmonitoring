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

require_relative '../../../libraries/CMAlarm.rb'
require_relative 'test_helpers.rb'

include Opscode::Rackspace::Monitoring

describe 'CMAlarm' do
  describe '#new' do
    it 'Errors without an entity' do
      expect { CMAlarm.new(test_credentials, 'bogus entity', 'test label') }.to raise_exception
    end

    describe 'without saved alarms' do
      before :all do
        @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
      end

      it 'takes three parameters and is a CMAlarm object' do
        test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, 'test label')
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMAlarm
        test_obj.obj.should eql nil
      end
    end
    
    describe 'with a saved alarm' do
      before :all do
        @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
        @alarm = generate_alarm(@cmentity_obj.entity_obj, "Good Test Alarm Label")
      end
      
      it 'loads nil for uncached existing tokens' do
        test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Bogus Test Alarm Label")
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMAlarm
        test_obj.obj.should eql nil
      end

      it 'loads cached tokens' do
        # This test is jumping ahead a bit in that it needs to call the lookup method to seed the cache. Meh.
        # Seed the cache
        test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Good Test Alarm Label")
        test_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMAlarm
        test_obj.obj.should eql nil
        test_obj.lookup_by_id(@alarm.id)
        test_obj.obj.should eql @alarm

        # Test cache use in the constructor
        # Note that the cache is a class variable
        test_obj_2 = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Good Test Alarm Label")
        test_obj_2.obj.should eql @alarm
      end
    end
  end
  
  describe '#lookup_by_id' do
    before :all do
      @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
      @alarm = generate_alarm(@cmentity_obj.entity_obj, "Good Test Alarm Label")
    end

    it 'returns nil with an invalid id' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "ID Lookup Test Alarm Label")
      test_obj.obj.should eql nil
      test_obj.lookup_by_id('bogus id')
      test_obj.obj.should eql nil
    end

    it 'returns an object with a valid id' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "ID Lookup Test Alarm Label")
      test_obj.obj.should eql nil
      test_obj.lookup_by_id(@alarm.id)
      test_obj.obj.should eql @alarm
    end
  end

  describe '#lookup_by_label' do
    before :all do
      @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
      @alarm = generate_alarm(@cmentity_obj.entity_obj, "Good Test Alarm Label")
    end

    it 'returns nil with an invalid id' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Label Lookup Test Alarm Label")
      test_obj.obj.should eql nil
      test_obj.lookup_by_label('bogus label')
      test_obj.obj.should eql nil
    end

    it 'returns an object with a valid id' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Label Lookup Test Alarm Label")
      test_obj.obj.should eql nil
      test_obj.lookup_by_label(@alarm.label)
      test_obj.obj.should eql @alarm
    end
  end
  
  describe '#to_s' do
    before :all do
      @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
      @alarm = generate_alarm(@cmentity_obj.entity_obj, "Test Alarm Label")
    end
    
    it 'returns a string when the object is nil' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, 'to_s Bogus Test Label')
      test_obj.obj.should eql nil
      test_obj.to_s.should be_an_instance_of String
    end

    it 'returns a string when the object not nil' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "to_s Test Alarm Label")
      test_obj.lookup_by_id(@alarm.id)
      test_obj.obj.should_not eql nil
      test_obj.to_s.should be_an_instance_of String
    end
  end

  describe '#update' do
    before :all do
      @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
    end

    it 'creates a new object when the current object is nil' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Update Test Alarm Label")
      test_obj.obj.should eql nil
      test_obj.update('label'                => 'Update Test 1',
                      'check'                => 'Test Check ID',
                      'notification_plan_id' => 'Test Notification Plan'
                      ).should eql true
      test_obj.obj.should_not eql nil
      test_obj.obj.label.should eql 'Update Test 1'
    end

    it 'updates an existing entity when the current object is not nil' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Update Test Alarm Label")
      test_obj.obj.should_not eql nil
      orig_id = test_obj.obj.id
      orig_id.should_not eql nil

      test_obj.update('label'                => 'Update Test 2',
                      'check'                => 'Test Check ID',
                      'notification_plan_id' => 'Test Notification Plan'
                      ).should eql true
      test_obj.obj.should_not eql nil
      test_obj.obj.label.should eql 'Update Test 2'
      test_obj.obj.id.should eql orig_id
    end

    it 'does not update the object when nothing is changed' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Update Test Alarm Label")
      test_obj.obj.should_not eql nil
      test_obj.obj.label.should eql 'Update Test 2'
      orig_obj = test_obj.obj.dup

      test_obj.update('label'                => 'Update Test 2',
                      'check'                => 'Test Check ID',
                      'notification_plan_id' => 'Test Notification Plan'
                      ).should eql false
      test_obj.obj.compare?(orig_obj).should eql true
    end
  end

  describe '#delete' do
    before :all do
      @cmentity_obj = seed_CMEntity(test_credentials, "Valid Alarm Test Entity")
    end

    it 'deletes the entity when the current object is not nil' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Delete Test Alarm Label")
      test_obj.update('label'                => 'Delete Test',
                      'check'                => 'Test Check ID',
                      'notification_plan_id' => 'Test Notification Plan')
      test_obj.obj.should_not eql nil
      CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Delete Test Alarm Label").obj.should_not eql nil

      test_obj.delete.should eql true
      test_obj.obj.should eql nil

      # Verify the token was actually deleted by looking it up again
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Delete Test Alarm Label")
      test_obj.obj.should eql nil
    end

    it 'returns false when the current object is nil' do
      test_obj = CMAlarm.new(test_credentials, @cmentity_obj.chef_label, "Delete Test Alarm Label")
      test_obj.obj.should eql nil
      test_obj.delete.should eql false
    end
  end

end
