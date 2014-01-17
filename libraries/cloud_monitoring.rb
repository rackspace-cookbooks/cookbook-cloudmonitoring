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
      # CM_credentials: Class for handling the various credential sources
      class CM_credentials
        def initialize(my_node, my_resource)
          @node = my_node
          @resource = @my_resource
          @databag_data = load_databag

          # @attribute_map: This is a mapping of how the attributes are named ant stored
          # in the various source structures
          @attribute_map = {
            api_key: {
              resource: 'rackspace_api_key',
              node:     '[:rackspace][:cloud_credentials][:api_key]',
              databag:  'apikey',
            },
            username: {
              resource: 'rackspace_username',
              node:     '[:rackspace][:cloud_credentials][:username]',
              databag:  'username',
            },
            auth_url: {
              resource: 'rackspace_auth_url',
              node:     'default[:rackspace_cloudmonitoring][:agent][:token]',
              databag:  'auth_url',
            },
            token: {
              resource: nil,
              node:     nil,
              databag:  'agent_token',
            },
          }
        end

        # get_attribute: get an attribute
        # PRE: None
        # POST: None
        def get_attribute(attribute_name)
          unless @attribute_map.key? attribute_name
            raise Exception, "Opscode::Rackspace::Monitoring::CM_credentials.get_attribute: Attribute #{attribute_name} not defined in @attribute_map"
          end

          unless @attribute_map[attribute_name][:resource].nil?
            # Resource attributes are called as methods, so use send to access the attribute
            resource = @resource.nil? ? nil : @resource.send(@attribute_map[attribute_name][:resource])
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_credentials.get_attribute: Resource value for attribute #{attribute_name}: #{resource}")
          end

          unless @attribute_map[attribute_name][:node].nil?
            # Note is a hash, so use eval to tack on the indexes
            begin
              node_val = eval("@node#{@attribute_map[attribute_name][:node]}")
            rescue Exception => e
              node_val = nil
            end
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_credentials.get_attribute: Node value for attribute #{attribute_name}: #{node_val}")
          end

          unless @attribute_map[attribute_name][:databag].nil?
            # databag is just a hash set by load_databag which is controlled in this class
            databag = @databag_data[@attribute_map[attribute_name][:databag]]
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_credentials.get_attribute: Databag value for attribute #{attribute_name}: #{databag}")
          end

          # I think this is about as clean as this code can be without redefining the LWRP arguments
          # and databag storage, which is simply too much of a refactor.
          ret_val =  _precidence_logic(resource, node_val, databag)
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_credentials.get_attribute: returning \"#{ret_val}\" for attribute #{attribute_name}")
          return ret_val
        end

        # load_databag: Load credentials from the databag
        # PRE: Databag details defined in node[:rackspace_cloudmonitoring][:auth][:databag] attributes
        # POST: None
        # RETURN VALUE: Data on success, empty hash on error
        # DOES NOT SET @databag_data
        def load_databag
          begin
            # Access the Rackspace Cloud encrypted data_bag
            return Chef::EncryptedDataBagItem.load(
                                                   @node[:rackspace_cloudmonitoring][:auth][:databag][:name],
                                                   @node[:rackspace_cloudmonitoring][:auth][:databag][:item]
                                                   )
          rescue Exception => e
            return {}
          end
        end

        # precidence_logic: Helper method to handle precidence of attributes
        # from the resource, node attributes, and databas
        # PRE: None
        # POST: None
        def _precidence_logic(resource, node, databag)
          # Precedence:
          # 1) new_resource variables (If available)
          # 2) Node data
          # 3) Data bag
          if resource
            return resource
          end
          if node
            return node
          end
          return databag
        end
      end # END CM_credentials

      # cm_api:  This class initializes the connection to the Cloud Monitoring API
      class CM_api
        # Initialize: Initialize the class
        # Opens connections to the API via Fog, will share connections when possible
        # PRE: credentials is a CM_credentials instance
        # POST: None
        # RETURN VALUE: None
        # Opens @cm class variable
        def initialize(credentials)
          username = credentials.get_attribute(:username)

          _get_cached_cm(username)
          unless @cm.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::cm_api.initialize: Reusing existing Fog connection for username #{username}")
            return
          end

          # No cached cm, create a new one
          Chef::Log.debug("Opscode::Rackspace::Monitoring::cm_api.initialize: creating new Fog connection for username #{username}")
          @cm = Fog::Rackspace::Monitoring.new(
                                               rackspace_api_key: credentials.get_attribute(:api_key),
                                               rackspace_username: username,
                                               rackspace_auth_url: credentials.get_attribute(:auth_url)
                                               )

          if @cm.nil?
            raise Exception, 'Opscode::Rackspace::Monitoring::cm_api.initialize: ERROR: Unable to connect to Fog'
          end
          Chef::Log.debug('Opscode::Rackspace::Monitoring::cm_api.initialize: Fog connection successful')

          _save_cached_cm(username)
        end

        # _*_cached_cm: Implement a local cache of cm variables using a class variable
        # Uses a single unique key
        # PRE: None
        # POST: None
        # RETURN VALUE: None; interacts directly with @cm
        def _get_cached_cm(username)
          unless defined?(@@cm_cache)
            @cm = nil
            return
          end

          @cm = @@cm_cache[username]
        end

        def _save_cached_cm(username)
          unless defined?(@@cm_cache)
            @@cm_cache = {}
          end

          @@cm_cache[username] = @cm
        end


        # get_cm: Getter for the @@cm class variable
        # PRE: Class initialized
        # POST: none
        # RETURN VALUE: Fog::Rackspace::Monitoring class
        def get_cm
          return @cm
        end
      end # END CM_api class

      # CM_obj_base: Common methods for interacting with MaaS Objects
      # Intended to be inherited as a base class
      # Common arguments for methods:
      #   obj: Current target object
      #   parent_obj: Parent object to call methods against for finding/generating obj
      #   debug_name: Name string to print in informational/diagnostic/debug messages
      class CM_obj_base
        # lookup_by_id: Locate an entity by ID string
        # PRE:
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_id(obj, parent_obj, debug_name, id)
          if id.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_id: ERROR: Passed nil id"
            return nil
          end

          unless obj.nil?
            if obj.id == id
              Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_id: Existing object hit for #{id}")
              return obj
            end
          end

          obj = parent_obj.find{ |sobj| sobj.id==id}
          if obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_id: No object found for #{id}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_id: New object found for #{id}")
          end

          return obj
        end

        # lookup_by_label: Lookup a check by label
        # PRE: none
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_label(obj, parent_obj, debug_name, label)
          if label.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_label: ERROR: Passed nil label"
          end

          unless obj.nil?
            if obj.label == label
              Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_label: Existing object hit for #{label}")
              return obj
            end
          end

          obj = parent_obj.find{ |sobj| sobj.label==label}
          if obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_label: No object found for #{label}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_id: New object found for #{label}.  ID: #{obj.id}")
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
          unless new_obj.compare? obj then
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
          if @obj.nil?
            return false
          end

          @obj.destroy
          return true
        end
      end # END CM_api class

      # cm_entity: Class handling entity operations
      class CM_entity < CM_obj_base
        # initialize: initialize the class
        # PRE: credentials is a CM_credentials instance, my_chef_label is unique for this entity
        # POST: None
        # RETURN VALUE: None
        def initialize(credentials, my_chef_label)
          @chef_label = my_chef_label
          @cm = CM_api.new(credentials).get_cm
          @username = credentials.get_attribute(:username)

          # Reuse an existing entity from our local cache, if present
          _get_cached_entity(@username, @chef_label)
          unless @entity_obj.nil?
            Chef::Log.debug('Opscode::Rackspace::Monitoring::cm_entity: Using entity saved in local cache')
            return
          end

          @entity_obj = nil
        end

        # _*_cached_entity: Implement a local cache of entities using a class variable
        # This DOES NOT use the node[] cache as it is simply for reusing Fog connections
        # Uses username and label as keys
        # PRE: None
        # POST: None
        # RETURN VALUE: None; interacts directly with @entity_obj
        def _get_cached_entity(username, label)
          unless defined?(@@entity_cache)
            @entity_obj = nil
            return
          end

          @entity_obj = @@entity_cache[username][label]
        end

        def _save_cached_entity(username, label)
          unless defined?(@@entity_cache)
            @@entity_cache = {}
          end

          unless @@entity_cache.key?(username)
            @@entity_cache[username] = {}
          end

          @@entity_cache[username][label] = @entity_obj
        end


        # get_entity_obj: Return the entity object
        # PRE: None
        # POST: None
        # Returns a Fog::Rackspace::Monitoring::Entity object or nil
        def get_entity_obj
          return @entity_obj
        end

        # get_entity_obj_id: Return the entity object id
        # PRE: None
        # POST: None
        # Returns a string or nil
        def get_entity_obj_id
          if @entity_obj.nil?
            return nil
          end

          return @entity_obj.id
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

          unless new_entity.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_entity._update_entity_obj: Caching entity with ID #{new_entity.id}")
            _save_cached_entity(@username, @chef_label)
          else
            Chef::Log.debug('Opscode::Rackspace::Monitoring::CM_entity._update_entity_obj: Caching EMPTY Entity')
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
            raise Exception, 'Opscode::Rackspace::Monitoring::CM_entity.lookup_entity_by_ip: ERROR: Passed nil ip'
          end

          unless @entity_obj.nil?
            if _lookup_entity_by_ip_checker(@entity_obj, ip)
              return @entity_obj
            end
          end

          return _update_entity_obj(@cm.entities.find{ |entity| _lookup_entity_by_ip_checker(entity, ip)})
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
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_entity.update_entity: Created new entity #{@entity_obj.label} (#{@entity_obj.id})")
            return true
          end

          unless @entity_obj.compare? orig_obj
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_entity.update_entity: Updated entity #{@entity_obj.label} (#{@entity_obj.id})")
            return true
          end

          return false
        end

        # delete_entity: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_entity
          orig_obj = @entity_obj
          if obj_delete(@entity_obj, @cm.entities, 'Entity')
            _update_entity_obj(nil)
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_entity.delete: Deleted entity #{@orig_obj.label} (#{@orig_obj.id})")
            return true
          end
          return false
        end

      end # END CM_entity class

      # CM_Child class: This is a generic class to be inherited for checks and alarms
      # as the two are handled amlost identically
      class CM_child < CM_obj_base
        def initialize(credentials, entity_chef_label, my_target_name, my_debug_name)
          @obj = nil
          @target_name = my_target_name
          @debug_name = my_debug_name
          @entity_chef_label = entity_chef_label

          @entity = CM_entity.new(credentials, entity_chef_label)
          if @entity.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).initialize: Unable to lookup entity with Chef label #{entity_chef_label}"
          end
        end

        # _get_target: Call send on the entity to get the target object
        # PRE: get_entity_obj PRE conditions met
        # POST: None
        # Return Value: Target Object
        def _get_target
          return @entity.get_entity_obj.send(@target_name)
        end

        # get_obj: Returns the check object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Check object or nil
        def get_obj
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

          entity_id = @entity.get_entity_obj_id
          return "#{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{@entity_chef_label}(#{entity_id})]"
        end

        # lookup_by_id: Lookup a child by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        def lookup_by_id(id)
          @obj = obj_lookup_by_id(@obj, _get_target, @debug_name, id)
          return @obj
        end

        # lookup_by_label: Lookup a child by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        def lookup_by_label(label)
          @obj = obj_lookup_by_label(@obj, _get_target, @debug_name, label)
          return @obj
        end

        # update: Update or create a new object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update(attributes = {})
          orig_obj = @obj
          @obj = obj_update(@obj, _get_target, @debug_name, attributes)
          if @obj.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).update: obj_update returned nil"
          end

          if orig_obj.nil?
            entity_id = @entity.get_entity_obj_id
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).update: Created new #{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            return true
          end

          unless @obj.compare? orig_obj
            entity_id = @entity.get_entity_obj_id
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).update: Updated #{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            return true
          end

          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete
          orig_obj = obj
          if obj_delete(@obj, _get_target, @target_name)
            _update_entity_obj(nil)

            entity_id = @entity.get_entity_obj_id
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).delete: Deleted #{@debug_name} #{@orig_obj.label} (#{@orig_obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            return true
          end
          return false
        end
      end # END CM_child class

      class CM_check < CM_child
        # Note that this initializer DOES NOT LOAD ANY CHECKS!
        # User must call a lookup function before calling update
        def initialize(credentials, entity_label)
          super(credentials, entity_label, :checks, 'Check')
        end
      end

      class CM_alarm < CM_child
        # Note that this initializer DOES NOT LOAD ANY ALARMS!
        # User must call a lookup function before calling update
        def initialize(credentials, entity_label)
          super(credentials, entity_label, :alarms, 'Alarm')
          @credentials = credentials
        end

        # get_credentials: return the credentials used
        # PRE: None
        # POST: None
        # RETURN VALUE: CM_credentials class
        # This is a *bit* of a hack as @credentials was originially saved in case get_example_alarm was called
        # which needs a cm object and should otherwise not be needed.  However, it makes our life slightly easier
        # in the alarm LWRP as we can use it to pass to the CM_check constructor to get the check ID.
        def get_credentials
          return @credentials
        end

        # get_example_alarm: Look up an alarm definition from the example API and return its criteria
        # This does not modify the current alarm object, but it does require the inherited CM_api class
        # PRE: None
        # POST: None
        # Return Value: bound_criteria string
        def get_example_alarm(example_id, example_values)
          @cm = CM_api.new(@credentials).get_cm
          return @cm.alarm_examples.evaluate(example_id, example_values).bound_criteria
        end
      end

      class CM_agent_token < CM_obj_base
        def initialize(credentials, token, label)
          @cm = CM_api.new(credentials).get_cm
          unless token.nil?
            @obj = obj_lookup_by_id(nil, @cm.agent_tokens, 'Agent_Token', token)
            unless @obj.nil?
              return
            end
          end

          if label.nil?
            raise Exception, 'Opscode::Rackspace::Monitoring::CM_agent_token.initialize: ERROR: Passed nil label'
          end

          @obj = obj_lookup_by_label(nil, @cm.agent_tokens, 'Agent_Token', label)
        end

        # get_obj: Returns the token object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::AgentToken object or nil
        def get_obj
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
            raise Exception, 'Opscode::Rackspace::Monitoring::CM_agent_token.update obj_update returned nil'
          end

          if orig_obj.nil?
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_agent_token.update: Created new agent token #{@obj.id}")
            return true
          end

          unless @obj.compare? orig_obj
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_agent_token.update: Updated agent token #{@obj.id}")
            return true
          end

          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_
          orig_obj = obj
          if obj_delete(@obj, @cm.agent_tokens, @target_name)
            @obj = nil
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_agent_token.delete: Deleted token #{@orig_obj.id}")
            return true
          end
          return false
        end
      end # END CM_tokens class

    end # END MODULE
  end
end
