# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Library:: cloud_monitoring
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
#

require_relative 'CMChild.rb'

module Opscode
  module Rackspace
    module Monitoring
      # CMCheck: Class for handling Cloud Monitoring Check objects
      class CMCheck < Opscode::Rackspace::Monitoring::CMChild
        # Note that this initializer DOES NOT LOAD ANY CHECKS!
        # User must call a lookup function before calling update
        def initialize(credentials, entity_label, my_label, use_cache = true)
          super(credentials, entity_label, 'checks', 'Check', my_label, use_cache)
        end
      end
    end # END MODULE
  end
end
