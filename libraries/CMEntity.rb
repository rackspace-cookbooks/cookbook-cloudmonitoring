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
require_relative 'CMCache.rb'

module Opscode
  module Rackspace
    module Monitoring
      # CMEntity: Class handling entity operations
      class CMEntity < Opscode::Rackspace::Monitoring::CMObjBase
        # initialize: initialize the class
        # PRE: credentials is a CMCredentials instance, my_chef_label is unique for this entity
        # POST: None
        # RETURN VALUE: None
        def initialize(credentials, my_chef_label, use_cache = true)
          # This class intentionally uses a class variable to share entity IDs across class instances
          # The class variable is guarded by use of the CMCache class which ensures IDs are utilized
          #    properly across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars

          # Initialize the base class
          super(find_pagination_limit: credentials.get_attribute(:pagination_limit))

          @chef_label = my_chef_label
          @cm = Opscode::Rackspace::Monitoring::CMApi.new(credentials).cm
          @username = credentials.get_attribute(:username)

          # Reuse an existing entity from our local cache, if present
          unless defined? @@entity_cache
            @@entity_cache = Opscode::Rackspace::Monitoring::CMCache.new(2)
          end

          if use_cache
            @entity_obj = @@entity_cache.get(@username, @chef_label)
          else
            # This is a testing codepath for high-level API tests where the cache interferes
            @entity_obj = nil
          end

          unless @entity_obj.nil?
            Chef::Log.debug('Opscode::Rackspace::Monitoring::CMEntity: Using entity saved in local cache')
          end
          # rubocop:enable ClassVars
        end

        # entity_obj: Return the entity object
        # PRE: None
        # POST: None
        # Returns a Fog::Rackspace::Monitoring::Entity object or nil
        def entity_obj
          return @entity_obj
        end

        # entity_obj_id: Return the entity object id
        # PRE: None
        # POST: None
        # Returns a string or nil
        def entity_obj_id
          if @entity_obj.nil?
            return nil
          end

          return @entity_obj.id
        end

        # chef_label: Return the chef label
        # PRE: None
        # POST: None
        # Returns a Fog::Rackspace::Monitoring::Entity object or nil
        def chef_label
          return @chef_label
        end

        # to_s: Print the class as a string
        # PRE: None
        # POST: None
        # RETURN VALUE: A string representing the class
        def to_s
          if @entity_obj.nil?
            return 'nil'
          end

          return "Entity #{@entity_obj.label} (#{@entity_obj.id})"
        end

        # _update_entity_obj: helper function to update @entity_obj, update the ID cache, and help keep the code DRY
        # PRE: new_entity is a valid Fog::Rackspace::Monitoring::Entity object
        # POST: None
        # RETURN VALUE: new_entity
        def _update_entity_obj(new_entity)
          @entity_obj = new_entity

          # Cache nill values, important for delete
          @@entity_cache.save(@entity_obj, @username, @chef_label) # rubocop:disable ClassVars
                                                                   # See comment in constructor

          if new_entity.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMEntity._update_entity_obj: Clearing cached entity for Chef entity #{@chef_label}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMEntity._update_entity_obj: Caching entity with ID #{new_entity.id} for Chef entity #{@chef_label}")
          end

          return new_entity
        end

        # lookup_entity_by_id: Locate an entity by ID string
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_id(id)
          return _update_entity_obj(obj_lookup_by_id(@entity_obj, @cm.entities, 'Entity', id))
        end

        # lookup_entity_by_label: Locate an entity by label string
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_label(label)
          return _update_entity_obj(obj_lookup_by_label(@entity_obj, @cm.entities, 'Entity', label))
        end

        # lookup_entity_by_ip: Locate an entity by IP address
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_ip(ip)
          # Search helper function
          def _lookup_entity_by_ip_checker(entity, tgtip)
            if entity.ip_addresses.nil?
              return false
            end

            entity.ip_addresses.each_pair do |key, value|
              if value == tgtip
                return true
              end
            end

            return false
          end

          if ip.nil?
            fail 'Opscode::Rackspace::Monitoring::CMEntity.lookup_entity_by_ip: ERROR: Passed nil ip'
          end

          unless @entity_obj.nil?
            if _lookup_entity_by_ip_checker(@entity_obj, ip)
              return @entity_obj
            end
          end

          return _update_entity_obj(obj_paginated_find(@cm.entities, 'entity') { |entity| _lookup_entity_by_ip_checker(entity, ip) })
        end

        # update_entity: Update or create a new monitoring entity
        # PRE: @entity_obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update_entity(attributes = {})
          orig_obj = @entity_obj
          _update_entity_obj(obj_update(@entity_obj, @cm.entities, 'Entity', attributes))

          if orig_obj.nil?
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMEntity.update_entity: Created new entity #{@entity_obj.label} (#{@entity_obj.id})")
            return true
          end

          unless @entity_obj.compare? orig_obj
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMEntity.update_entity: Updated entity #{@entity_obj.label} (#{@entity_obj.id})")
            return true
          end

          return false
        end

        # delete_entity: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_entity
          orig_obj = @entity_obj.dup unless @entity_obj.nil?
          if obj_delete(@entity_obj, @cm.entities, 'Entity')
            _update_entity_obj(nil)
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMEntity.delete: Deleted entity #{orig_obj.label} (#{orig_obj.id})")
            return true
          end
          return false
        end
      end # END CMEntity class
    end # END MODULE
  end
end
