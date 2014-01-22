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
include Opscode::Rackspace::Monitoring

#
# Dummy object for testing
# Behaves loosly like Fog objects
# Fog is currently mocked, but the mocking has no backing storage so it just returns
#  random data.  This class is intended to fill the gap.  It is ONLY intended for
#  testing CMObjBase, it will not have sufficient coverage for the inheriting classes
#  and LWRPs.
#
class DummyObject
  attr_accessor :id, :label, :saved, :destroyed
  
  def initialize(arg_hash)
    @id = arg_hash[:id]
    @label = arg_hash[:label]
    @saved = false
    @destroyed = false
  end
  
  #
  # Methods mimicing Fog
  #
  def save
    @saved = true
  end
  
  def destroy
    @destroyed = true
  end

  def compare?(other_obj)
    if @destroyed or other_obj.destroyed
      return false
    end

    if @id != other_obj.id
      return false
    end

    if @label != other_obj.label
      return false
    end

    return true
  end

end

# Dummy parent object for testing: Behave like an array, except for a new method
#  which returns a DummyObject
#
# This doesn't behave exactly like Fog as we save the new object as soon as it is
# created (not on DummyObject.save) but it will suffice for our needs.
class DummyParentObject < Array
  def new(*args)
    newObj = DummyObject.new(*args)
    self.push(newObj)
    return newObj
  end
end

describe 'CMObjBase' do

  #
  # Sanity tests around our Dummy objects
  #
  describe 'Dummy Object Sanity Checks' do
    describe 'DummyObject' do
      it 'creates a dummy object properly' do
        target_obj = DummyObject.new({id: 'id1', label: 'label1'})
        target_obj.id.should eql 'id1'
        target_obj.label.should eql "label1"
        target_obj.saved.should eql false
        target_obj.destroyed.should eql false
      end
    end

    describe 'DummyParentObject' do
      before :all do
        @parent_obj = DummyParentObject.new
      end
      
      it 'is initially an empty array' do
        @parent_obj.should == []
      end

      it 'allows creation of DummyObjects' do
        @parent_obj.new({id: 'id1', label: 'label1'})
        @parent_obj[0].id.should eql 'id1'
        @parent_obj[0].label.should eql "label1"
        @parent_obj[0].saved.should eql false
        @parent_obj[0].destroyed.should eql false
      end
    end
  end     

  #
  # Actual tests
  #
  describe '#obj_lookup_by_id' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = DummyParentObject.new
    end

    it 'returns nil when there are no objects in the parent' do
      @parent_obj.should == [] # Sanity
      @test_obj.obj_lookup_by_id(nil, @parent_obj, 'empty parent test', "foo").should eql nil
    end

    it 'finds objects in the parent' do
      target_obj = @parent_obj.new({id: 'id1', label: 'label1'})
      @test_obj.obj_lookup_by_id(nil, @parent_obj, 'obj find test', 'id1').should eql target_obj
    end

    it 'returns nil when an object is not found' do
      8.times do |i|
                                           @parent_obj.new({id: "id#{i}", label: "label#{i}"})
      end
      @test_obj.obj_lookup_by_id(nil, @parent_obj, 'obj not found test', "id9").should eql nil
    end

    it 'does not search the parent when the target is passed' do
      target_obj = DummyObject.new({id: 'id1', label: 'label1'})
      @parent_obj.should == [] # Sanity
      # Note target_obj is NOT in the parent array and the parent array is empty
      # If obj_lookup_by_id fails to return target_obj it should return nil per
      #  earlier test 'returns nil when there are no objects in the parent'
      @test_obj.obj_lookup_by_id(target_obj, @parent_obj, 'existing obj hit test', target_obj.id).should eql target_obj
    end
  end

  describe '#obj_lookup_by_label' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = DummyParentObject.new
    end

    it 'returns nil when there are no objects in the parent' do
      @parent_obj.should == [] # Sanity
      @test_obj.obj_lookup_by_label(nil, @parent_obj, 'empty parent test', "foo").should eql nil
    end

    it 'finds objects in the parent' do
      target_obj = @parent_obj.new({id: 'id1', label: 'label1'})
      @test_obj.obj_lookup_by_label(nil, @parent_obj, 'obj find test', 'label1').should eql target_obj
    end

    it 'returns nil when an object is not found' do
      8.times do |i|
        @parent_obj.new({id: "id#{i}", label: "label#{i}"})
      end
      @test_obj.obj_lookup_by_label(nil, @parent_obj, 'obj not found test', "label9").should eql nil
    end

    it 'does not search the parent when the target is passed' do
      target_obj = DummyObject.new({id: 'id1', label: 'label1'})
      @parent_obj.should == [] # Sanity
      # Note target_obj is NOT in the parent array and the parent array is empty
      # If obj_lookup_by_label fails to return target_obj it should return nil per
      #  earlier test 'returns nil when there are no objects in the parent'
      @test_obj.obj_lookup_by_label(target_obj, @parent_obj, 'existing obj hit test', target_obj.label).should eql target_obj
    end
  end

  describe '#obj_update' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = DummyParentObject.new
    end

    it 'creates a new object when obj is nil' do
      target_obj = @test_obj.obj_update(nil, @parent_obj, "new obj test", {id: 'id1', label: 'label1'})
      target_obj.id.should eql 'id1'
      target_obj.label.should eql 'label1'
      target_obj.saved.should eql true
      target_obj.destroyed.should eql false
    end

    it 'replaces an object when the object exists' do
      orig_target_obj = @parent_obj.new({id: 'id1', label: 'label1'})
      target_obj = @test_obj.obj_update(orig_target_obj, @parent_obj, "obj replacement test", {id: 'id1', label: "label2"})
      # This test is flawed in that it doesn't test for replacement.
      # However the current framework doesn't allow for that
      target_obj.id.should eql 'id1'
      target_obj.label.should eql "label2"
      target_obj.saved.should eql true
      target_obj.destroyed.should eql false
    end

    it 'does not modify if not required' do
      orig_target_obj = @parent_obj.new({id: 'id1', label: 'label1'})
      @test_obj.obj_update(orig_target_obj, @parent_obj, "obj modification test", {id: 'id1', label: 'label1'}).should eql orig_target_obj
    end
  end

  describe '#obj_delete' do
    before :each do
      @test_obj = CMObjBase.new
      @parent_obj = DummyParentObject.new
      @target_obj = @parent_obj.new({id: 'id1', label: 'label1'})
    end

    it 'destroys obj' do
      @test_obj.obj_delete(@target_obj, @parent_obj, 'destruction test').should eql true
      @target_obj.destroyed.should eql true
    end

    it 'does not try and destroy nil objects' do
      @test_obj.obj_delete(nil, @parent_obj, 'destruction test').should eql false
    end
  end   
end
