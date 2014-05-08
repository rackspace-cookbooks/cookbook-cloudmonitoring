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

require_relative 'CMObjBase.rb'
require_relative 'CMApi.rb'

module Opscode
  module Rackspace
    module Monitoring
      # CMAgentToken: Class for handling Cloud Monitoring Agent Token objects
      class CMAgentToken < Opscode::Rackspace::Monitoring::CMObjBase
        def initialize(credentials, token, label)
          # Initialize the base class
          super(find_pagination_limit: credentials.get_attribute(:pagination_limit))

          @cm = Opscode::Rackspace::Monitoring::CMApi.new(credentials).cm
          unless token.nil?
            @obj = obj_lookup_by_id(nil, @cm.agent_tokens, 'Agent_Token', token)
            unless @obj.nil?
              return
            end
          end

          if label.nil?
            fail 'Opscode::Rackspace::Monitoring::CMAgentToken.initialize: ERROR: Passed nil label'
          end

          @obj = obj_lookup_by_label(nil, @cm.agent_tokens, 'Agent_Token', label)
        end

        # obj: Returns the token object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::AgentToken object or nil
        def obj
          return @obj
        end

        # to_s: Print the class as a string
        # PRE: None
        # POST: None
        # RETURN VALUE: A string representing the class
        def to_s
          if @obj.nil?
            return 'nil'
          end

          return "Alarm Token #{@obj.id}"
        end

        # update: Update or create a new token object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update(attributes = {})
          orig_obj = @obj
          @obj = obj_update(@obj, @cm.agent_tokens, 'Agent_Token', attributes)
          if @obj.nil?
            fail 'Opscode::Rackspace::Monitoring::CMAgentToken.update obj_update returned nil'
          end

          if orig_obj.nil?
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMAgentToken.update: Created new agent token #{@obj.id}")
            return true
          end

          unless @obj.compare? orig_obj
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMAgentToken.update: Updated agent token #{@obj.id}")
            return true
          end

          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete
          orig_obj_id = @obj.id unless @obj.nil?
          if obj_delete(@obj, @cm.agent_tokens, @target_name)
            @obj = nil
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMAgentToken.delete: Deleted token #{orig_obj_id}")
            return true
          end
          return false
        end
      end # END CMAgentToken class
    end # END MODULE
  end
end
