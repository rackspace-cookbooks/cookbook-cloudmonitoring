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

require_relative '../../../libraries/CMCache.rb'

describe 'CMCache' do
  before :each do
    # Test a 3 level cache, which should be quite sufficient to exercise the code.
    @test_cache = Opscode::Rackspace::Monitoring::CMCache.new(3)

    # Create a second cache to test for crosstalk due to some unforseen insanity
    # (We *are* allowing class variables, after all)
    @second_cache = Opscode::Rackspace::Monitoring::CMCache.new(3)
  end

  describe '#new' do
    it 'takes a parameter and is a CMCache object' do
      @test_cache.should be_an_instance_of Opscode::Rackspace::Monitoring::CMCache
    end
  end

  it 'Accepts new single values' do
    @test_cache.save('MyValue', 'Key1', 'Key2', 'Key3')
    @test_cache.get('Key1', 'Key2', 'Key3').should eql 'MyValue'
  end

  it 'Accepts multiple values without corruption or crosstalk' do
    # Save
    10.times do |x|
      10.times do |y|
        10.times do |z|
          @test_cache.save("#{x}_#{y}_#{z}", x, y, z)
        end
      end
    end

    # Verify
    # Intentionally in a second to catch lost values
    10.times do |x|
      10.times do |y|
        10.times do |z|
          @test_cache.get(x, y, z).should eql "#{x}_#{y}_#{z}"
          # Verify no crosstalk
          @second_cache.get(x, y, z).should_not eql "#{x}_#{y}_#{z}"
        end
      end
    end
  end

  it 'Should error on the wrong number of arguments' do
    expect { @test_cache.save('foo', 'bar') }.to raise_error
    expect { @test_cache.get('foo', 'bar') }.to raise_error
  end

  it 'Should error on nil keys' do
    expect { @test_cache.save('MyValue', nil, 'Key2', 'Key3') }.to raise_error
  end
end
