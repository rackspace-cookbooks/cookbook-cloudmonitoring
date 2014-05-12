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
require_relative '../../../libraries/CMObjBase.rb'
require_relative '../../../libraries/mock_data.rb'
include Opscode::Rackspace::Monitoring

# CMObjBaseTestHelpers: Helper methods/classes for the tests
module CMObjBaseTestHelpers
  # dummy_parent_object: Return a dummy patent object for testing
  # Code deduplication method: Provides a single definition for what is mocking the object.
  def dummy_parent_object
    return MockData::MockMonitoringParent.new(MockData::MockMonitoringEntity)
  end
  module_function :dummy_parent_object
end

describe 'CMObjBase' do
  describe '#obj_paginated_find' do
    before :each do
      @parent_obj = CMObjBaseTestHelpers.dummy_parent_object
      if @parent_obj != []
        fail '@parent_obj not empty after initialization'
      end
    end

    it 'locates all objects in a paginated response' do
      # Limit to 10 for pagination testing (5 pages)
      @test_obj = CMObjBase.new(find_pagination_limit: 10)

      # Seed the mock object with 50 objects
      50.times do |c|
        @parent_obj.new(label: "Test Object #{c}").save
      end
      @parent_obj.length.should eql 50

      # Find them!
      50.times do |c|
        @test_obj.obj_paginated_find(@parent_obj, 'paginated find test') { |o| o.label == "Test Object #{c}" }.should eql @parent_obj[c]
      end
    end

    it 'Passes find_pagination_limit through to the API' do
      # Test via illegal value
      @test_obj = CMObjBase.new(find_pagination_limit: 0)
      expect { @test_obj.obj_paginated_find(@parent_obj, 'find_pagination_limit test') { |o| o.label == 'Test Object 0' } }.to raise_exception
    end
  end

  describe '#obj_lookup_by_id' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = CMObjBaseTestHelpers.dummy_parent_object
      if @parent_obj != []
        fail '@parent_obj not empty after initialization'
      end
    end

    it 'returns nil when there are no objects in the parent' do
      @test_obj.obj_lookup_by_id(nil, @parent_obj, 'empty parent test', 'foo').should eql nil
    end

    it 'finds objects in the parent' do
      target_obj = @parent_obj.new(label: 'label1')
      target_obj.save
      @test_obj.obj_lookup_by_id(nil, @parent_obj, 'obj find test', target_obj.id).should eql target_obj
    end

    it 'returns nil when an object is not found' do
      8.times do |i|
        @parent_obj.new(label: "label#{i}").save
      end
      @test_obj.obj_lookup_by_id(nil, @parent_obj, 'obj not found test', 'id9').should eql nil
    end

    it 'does not search the parent when the target is passed' do
      target_obj = @parent_obj.new(label: 'label1')
      # Note target_obj is NOT in the parent array and the parent array is empty as we didn't call save
      # If obj_lookup_by_id fails to return target_obj it should return nil per
      #  earlier test 'returns nil when there are no objects in the parent'
      @test_obj.obj_lookup_by_id(target_obj, @parent_obj, 'existing obj hit test', target_obj.id).should eql target_obj
    end
  end

  describe '#obj_lookup_by_label' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = CMObjBaseTestHelpers.dummy_parent_object
      if @parent_obj != []
        fail '@parent_obj not empty after initialization'
      end
    end

    it 'returns nil when there are no objects in the parent' do
      @test_obj.obj_lookup_by_label(nil, @parent_obj, 'empty parent test', 'foo').should eql nil
    end

    it 'finds objects in the parent' do
      target_obj = @parent_obj.new(label: 'label1')
      target_obj.save
      @test_obj.obj_lookup_by_label(nil, @parent_obj, 'obj find test', 'label1').should eql target_obj
    end

    it 'returns nil when an object is not found' do
      8.times do |i|
        @parent_obj.new(label: "label#{i}").save
      end
      @test_obj.obj_lookup_by_label(nil, @parent_obj, 'obj not found test', 'label9').should eql nil
    end

    it 'does not search the parent when the target is passed' do
      target_obj = @parent_obj.new(label: 'label1')
      # Note target_obj is NOT in the parent array and the parent array is empty as we didn't call save
      # If obj_lookup_by_label fails to return target_obj it should return nil per
      #  earlier test 'returns nil when there are no objects in the parent'
      @test_obj.obj_lookup_by_label(target_obj, @parent_obj, 'existing obj hit test', target_obj.label).should eql target_obj
    end
  end

  describe '#obj_update' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = CMObjBaseTestHelpers.dummy_parent_object
    end

    it 'creates a new object when obj is nil' do
      target_obj = @test_obj.obj_update(nil, @parent_obj, 'new obj test', label: 'label1')
      target_obj.label.should eql 'label1'
      @parent_obj.length.should eql 1
      @parent_obj[0].should eql target_obj
    end

    it 'replaces an object when the object exists' do
      orig_target_obj = @parent_obj.new(label: 'label1')
      orig_target_obj.save
      @parent_obj[0].should eql orig_target_obj

      target_obj = @test_obj.obj_update(orig_target_obj, @parent_obj, 'obj replacement test', label: 'label2')

      target_obj.should_not eql orig_target_obj
      target_obj.id.should eql orig_target_obj.id
      target_obj.label.should eql 'label2'

      @parent_obj.length.should eql 1
      @parent_obj[0].should eql target_obj
    end

    it 'does not modify if not required' do
      orig_target_obj = @parent_obj.new(label: 'label1')
      @test_obj.obj_update(orig_target_obj, @parent_obj, 'obj modification test', label: 'label1').should eql orig_target_obj
      @parent_obj.length.should eql 0
    end
  end

  describe '#obj_delete' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = CMObjBaseTestHelpers.dummy_parent_object
      @target_obj = @parent_obj.new(label: 'label1')
      @target_obj.save
      fail 'Failed to save target' if @parent_obj.length != 1
    end

    it 'destroys obj' do
      @test_obj.obj_delete(@target_obj, @parent_obj, 'destruction test').should eql true
      @parent_obj.length.should eql 0
    end

    it 'does not try and destroy nil objects' do
      @test_obj.obj_delete(nil, @parent_obj, 'destruction test').should eql false
      @parent_obj.length.should eql 1
    end
  end
end
