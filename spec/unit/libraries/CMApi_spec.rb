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

require_relative '../../../libraries/CMApi.rb'
require_relative '../../../libraries/CMCredentials.rb'

include Opscode::Rackspace::Monitoring

describe 'CMApi' do
  before :each do
    credentials = CMCredentials.new({
                                       'rackspace_cloudmonitoring' => { 'mock' => true },
                                       'rackspace' => { 'cloud_credentials' => {
                                           'username' => 'Mr. Mockson',
                                           'api_key'  => 'Woodruff'
                                         } }
                                     }, nil)
    @api_obj = CMApi.new(credentials)
  end

  describe '#new' do
    it 'takes a parameter and is a CMApi object' do
      @api_obj.should be_an_instance_of Opscode::Rackspace::Monitoring::CMApi
    end
  end

  describe 'cm' do
    it 'does not return nil' do
      @api_obj.cm.should_not be nil
    end

    it 'should be a mock class' do
      @api_obj.cm.should be_an_instance_of Opscode::Rackspace::Monitoring::MockData::MockMonitoring
    end
  end
end
