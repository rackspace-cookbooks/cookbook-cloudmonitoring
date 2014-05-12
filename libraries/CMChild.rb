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
require_relative 'CMEntity.rb'
require_relative 'CMCache.rb'

module Opscode
  module Rackspace
    module Monitoring
      # CMChild class: This is a generic class to be inherited for checks and alarms
      # as the two are handled amlost identically
      class CMChild < Opscode::Rackspace::Monitoring::CMObjBase
        # initialize: initialize the class
        # PRE: credentials is a CMCredentials instance, my_label is unique for this entity
        # POST: None
        # RETURN VALUE: None
        def initialize(credentials, entity_chef_label, my_target_name, my_debug_name, my_label, use_cache = true)
          # This class intentionally uses a class variable to share object IDs across class instances
          # The class variable is guarded by use of the CMCache class which ensures IDs are utilized
          #    properly across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars

          # Initialize the base class
          super(find_pagination_limit: credentials.get_attribute(:pagination_limit))

          @target_name = my_target_name
          @debug_name = my_debug_name
          @entity_chef_label = entity_chef_label

          @entity = Opscode::Rackspace::Monitoring::CMEntity.new(credentials, entity_chef_label)
          if @entity.entity_obj.nil?
            fail "Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).initialize: Unable to lookup entity with Chef label #{entity_chef_label}"
          end

          @username = credentials.get_attribute(:username)
          @label = my_label
          unless defined? @@obj_cache
            @@obj_cache = Opscode::Rackspace::Monitoring::CMCache.new(4)
          end

          if use_cache
            @obj = @@obj_cache.get(@username, @entity_chef_label, @target_name, @label)
          else
            # This is a testing codepath for high-level API tests where the cache interferes
            @obj = nil
          end

          # rubocop:enable ClassVars
        end

        # _get_target: Call send on the entity to get the target object
        # PRE: get_entity_obj PRE conditions met
        # POST: None
        # Return Value: Target Object
        def _get_target
          return @entity.entity_obj.send(@target_name)
        end

        # obj: Returns the check object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Check object or nil
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

          entity_id = @entity.entity_obj_id
          return "#{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{@entity_chef_label}(#{entity_id})]"
        end

        # _update_obj: helper function to update @obj, update the cache, and help keep the code DRY
        # PRE: new_entity is a valid Fog::Rackspace::Monitoring::#{foo} object
        # POST: None
        # RETURN VALUE: new_entity
        def _update_obj(new_obj)
          @obj = new_obj

          @@obj_cache.save(@obj, @username, @entity_chef_label, @target_name, @label)  # rubocop:disable ClassVars
                                                                                       # See comment in constructor
          # Disable long line warnings for the logs, no simple way to shorten them
          # rubocop:disable LineLength
          if new_obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name})._update_obj: Clearing object cache for #{@label} #{@debug_name} ")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name})._update_obj: Caching #{@debug_name} object with ID #{new_obj.id} for #{@label} #{@debug_name}")
          end
          # rubocop:enable LineLength

          return new_obj
        end

        # lookup_by_id: Lookup a child by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        def lookup_by_id(id)
          return _update_obj(obj_lookup_by_id(@obj, _get_target, @debug_name, id))
        end

        # lookup_by_label: Lookup a child by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        def lookup_by_label(label)
          return _update_obj(obj_lookup_by_label(@obj, _get_target, @debug_name, label))
        end

        # update: Update or create a new object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update(attributes = {})
          orig_obj = @obj
          _update_obj(obj_update(@obj, _get_target, @debug_name, attributes))
          if @obj.nil?
            fail "Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).update: obj_update returned nil"
          end

          # Disable long line warnings for the info logs, no simple way to shorten them
          # rubocop:disable LineLength
          if orig_obj.nil?
            entity_id = @entity.entity_obj_id
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).update: Created new #{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            return true
          end

          unless @obj.compare? orig_obj
            entity_id = @entity.entity_obj_id
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).update: Updated #{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            return true
          end

          # rubocop:enable LineLength

          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete
          orig_obj = @obj.dup unless @obj.nil?
          if obj_delete(@obj, _get_target, @target_name)
            _update_obj(nil)

            entity_id = @entity.entity_obj_id

            # Disable long line warnings for the info logs, no simple way to shorten them
            # rubocop:disable LineLength
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).delete: Deleted #{@debug_name} #{orig_obj.label} (#{orig_obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            # rubocop:enable LineLength

            return true
          end
          return false
        end
      end # END CMChild class
    end # END MODULE
  end
end
