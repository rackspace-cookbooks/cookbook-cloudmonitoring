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

module Opscode
  module Rackspace
    module Monitoring
      # CMObjBase: Common methods for interacting with MaaS Objects
      # Intended to be inherited as a base class
      # Common arguments for methods:
      #   obj: Current target object
      #   parent_obj: Parent object to call methods against for finding/generating obj
      #   debug_name: Name string to print in informational/diagnostic/debug messages
      class CMObjBase
        # paginated_find: Perform a .find call taking into account Fog pagination
        # https://github.com/fog/fog/issues/2469
        # PRE: parent_obj supports the all() method which accepts a marker option and returns an Enumerable class
        # POST: None
        # RETURN VALUE: Value of find method
        def obj_paginated_find(parent_obj, debug_name, &block)
          marker = nil
          while true
            # Obtain a block of objects starting at marker
            search_obj = parent_obj.all({marker: marker})
            
            # Search using the provided block
            ret_val = search_obj.find &block
            unless ret_val == nil
              return ret_val
            end
              
            # No match: Return nil if there is no marker (no further results / no pagination)
            if search_obj.marker == nil
              return nil
            end

            marker = search_obj.marker
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).obj_paginated_find: Requesting additional page of results")
          end
        end
            

        # lookup_by_id: Locate an entity by ID string
        # PRE:
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_id(obj, parent_obj, debug_name, id)
          if id.nil?
            fail "Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_id: ERROR: Passed nil id"
          end

          unless obj.nil?
            if obj.id == id
              Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_id: Existing object hit for #{id}")
              return obj
            end
          end

          obj = obj_paginated_find(parent_obj, debug_name) { |sobj| sobj.id == id }
          if obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_id: No object found for #{id}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_id: New object found for #{id}")
          end

          return obj
        end

        # lookup_by_label: Lookup a check by label
        # PRE: none
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_label(obj, parent_obj, debug_name, label)
          if label.nil?
            fail "Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_label: ERROR: Passed nil label"
          end

          unless obj.nil?
            if obj.label == label
              Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_label: Existing object hit for #{label}")
              return obj
            end
          end

          obj = obj_paginated_find(parent_obj, debug_name) { |sobj| sobj.label == label }
          if obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_label: No object found for #{label}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMObjBase(#{debug_name}).lookup_by_id: New object found for #{label}.  ID: #{obj.id}")
          end

          return obj
        end

        # update: Update or create a new object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns updated obj
        # Idempotent: Does not update entities unless required
        def obj_update(obj, parent_obj, debug_name, attributes)
          new_obj = parent_obj.new(attributes)
          if obj.nil?
            new_obj.save
            return new_obj
          end

          new_obj.id = obj.id
          # Compare attributes
          unless new_obj.compare? obj
            # It's different
            new_obj.save
            return new_obj
          end

          return obj
        end

        # obj_delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def obj_delete(obj, parent_obj, debug_name)
          if obj.nil?
            return false
          end

          obj.destroy
          return true
        end
      end # END CMObjBase class
    end # END MODULE
  end
end
