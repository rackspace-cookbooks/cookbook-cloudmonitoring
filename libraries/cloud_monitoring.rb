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
      # CMCache: Implement a cache with a variable dimensional key structure in memory
      class CMCache
        # initialize: Class constructor
        # PRE: my_num_keys: Number of keys this cache will use
        # POST: None
        # RETURN VALUE: None

        # Disable rubocop eval warnings
        # This class uses eval to metaprogram, but all the keys should come from inside the code.
        # User data should not be used for keys, documented in PRE conditions.
        # rubocop:disable Eval

        def initialize(my_num_keys)
          @num_keys = my_num_keys
        end

        # get: Get a value from the cache
        # PRE: Keys must be strings, not symbols
        #      Keys must be defined in code and not come from user input for security
        # POST: None
        # RETURN VALUE: None
        def get(*keys)
          unless keys.length == @num_keys
            arg_count = keys.length
            fail "Opscode::Rackspace::Monitoring::CMCache.get: Key count mismatch (#{@num_keys}:#{arg_count})"
          end

          unless defined?(@cache)
            return nil
          end

          eval_str = '@cache'
          (0...@num_keys).each do |i|
            key = keys[i]
            cval = eval(eval_str)
            unless cval.key?(key)
              return nil
            end

            eval_str += "[\"#{key}\"]"
          end

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCache.get: Returning cached value from #{eval_str}")
          return eval(eval_str)
        end

        # get: Save a value to the cache
        # PRE: Keys must be strings, not symbols
        #      Keys must be defined in code and not come from user input for security
        # POST: None
        # RETURN VALUE: Data or nil
        def save(value, *keys)
          unless keys.length == @num_keys
            arg_count = keys.length
            fail "Opscode::Rackspace::Monitoring::CMCache.save: Key count mismatch (#{@num_keys}:#{arg_count})"
          end

          unless defined?(@cache)
            @cache = {}
          end

          eval_str = '@cache'
          (0...@num_keys).each do |i|
            key = keys[i]
            if key.nil?
              fail "Opscode::Rackspace::Monitoring::CMCache.save: Nil key at index #{i})"
            end

            if key.length <= 0
              fail "Opscode::Rackspace::Monitoring::CMCache.save: Empty key at index #{i})"
            end

            cval = eval(eval_str)
            unless cval.key?(key)
              eval("#{eval_str}[\"#{key}\"] = {}")
            end

            eval_str += "[\"#{key}\"]"
          end

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCache.save: Saving #{value} to #{eval_str}")
          eval("#{eval_str} = value")

          # Re-enable eval checks
          # rubocop:enable Eval
        end

        # dump: Return the internal cache dictionary
        # Intended for debugging
        # PRE: None
        # POST: None
        # RETURN VALUE: Internal cache
        def dump
          return @cache
        end
      end # END CMCache

      # CMCredentials: Class for handling the various credential sources
      class CMCredentials
        def initialize(my_node, my_resource)
          @node = my_node
          @resource = my_resource
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
              node:     '[:rackspace_cloudmonitoring][:auth][:url]',
              databag:  'auth_url',
            },
            token: {
              resource: nil,
              node:     '[:rackspace_cloudmonitoring][:agent][:token]',
              databag:  'agent_token',
            },
          }
        end

        # get_attribute: get an attribute
        # PRE: attribute_name must be defined in code and not come from user input for security
        # POST: None
        #
        # Disable Cyclomatic Complexity check as we're right on the threshold, and I don't believe breaking this up
        #   will improve readbility or flow.
        # rubocop:disable CyclomaticComplexity
        def get_attribute(attribute_name)
          unless @attribute_map.key? attribute_name
            fail "Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Attribute #{attribute_name} not defined in @attribute_map"
          end

          unless @attribute_map[attribute_name][:resource].nil?
            # Resource attributes are called as methods, so use send to access the attribute
            resource = @resource.nil? ? nil : @resource.send(@attribute_map[attribute_name][:resource])
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Resource value for attribute #{attribute_name}: #{resource}")
          end

          unless @attribute_map[attribute_name][:node].nil?
            # Note is a hash, so use eval to tack on the indexes
            begin
              # Disable rubocop eval warnings
              # The @attribute_map[attribute_name][:node] variable is set in the constructor
              #   Security for attribute_name documented in PRE conditions
              # rubocop:disable Eval
              node_val = eval("@node#{@attribute_map[attribute_name][:node]}")
              # rubocop:enable Eval
            rescue NoMethodError
              node_val = nil
            end
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Node value for attribute #{attribute_name}: #{node_val}")
          end

          unless @attribute_map[attribute_name][:databag].nil?
            # databag is just a hash set by load_databag which is controlled in this class
            databag = @databag_data[@attribute_map[attribute_name][:databag]]
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Databag value for attribute #{attribute_name}: #{databag}")
          end

          # I think this is about as clean as this code can be without redefining the LWRP arguments
          # and databag storage, which is simply too much of a refactor.
          ret_val =  _precidence_logic(resource, node_val, databag)
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: returning \"#{ret_val}\" for attribute #{attribute_name}")
          return ret_val
        end
        # rubocop:enable CyclomaticComplexity

        # load_databag: Load credentials from the databag
        # PRE: Databag details defined in node[:rackspace_cloudmonitoring][:auth][:databag] attributes
        # POST: None
        # RETURN VALUE: Data on success, empty hash on error
        # DOES NOT SET @databag_data
        def load_databag
          # Access the Rackspace Cloud encrypted data_bag
          return Chef::EncryptedDataBagItem.load(@node[:rackspace_cloudmonitoring][:auth][:databag][:name],
                                                 @node[:rackspace_cloudmonitoring][:auth][:databag][:item])
        # Chef::Exceptions::ValidationFailed is thrown in real use when the databag is not in use
        # Chef::Exceptions::InvalidDataBagPath is thrown by test kitchen when there are no databags
        rescue Chef::Exceptions::ValidationFailed, Chef::Exceptions::InvalidDataBagPath
          return {}
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
      end # END CMCredentials

      # CMApi:  This class initializes the connection to the Cloud Monitoring API
      class CMApi
        # Initialize: Initialize the class
        # Opens connections to the API via Fog, will share connections when possible
        # PRE: credentials is a CMCredentials instance
        # POST: None
        # RETURN VALUE: None
        # Opens @cm class variable
        def initialize(credentials)
          # This class intentionally uses a class method to share Fog connections across class instances
          # The class variable is guarded by use of the CMCache class which ensures proper connections are utilized
          #    across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars
          username = credentials.get_attribute(:username)
          unless defined? @@cm_cache
            @@cm_cache = CMCache.new(1)
          end
          @cm = @@cm_cache.get(username)
          unless @cm.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi.initialize: Reusing existing Fog connection for username #{username}")
            return
          end

          # No cached cm, create a new one
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi.initialize: creating new Fog connection for username #{username}")
          @cm = Fog::Rackspace::Monitoring.new(
                                               rackspace_api_key: credentials.get_attribute(:api_key),
                                               rackspace_username: username,
                                               rackspace_auth_url: credentials.get_attribute(:auth_url)
                                               )

          if @cm.nil?
            fail 'Opscode::Rackspace::Monitoring::CMApi.initialize: ERROR: Unable to connect to Fog'
          end
          Chef::Log.debug('Opscode::Rackspace::Monitoring::CMApi.initialize: Fog connection successful')

          @@cm_cache.save(@cm, username)

          # Re-enable ClassVars rubocop errors
          # rubocop:enable ClassVars
        end

        # cm: Getter for the @@cm class variable
        # PRE: Class initialized
        # POST: none
        # RETURN VALUE: Fog::Rackspace::Monitoring class
        def cm
          return @cm
        end
      end # END CMApi class

      # CMObjBase: Common methods for interacting with MaaS Objects
      # Intended to be inherited as a base class
      # Common arguments for methods:
      #   obj: Current target object
      #   parent_obj: Parent object to call methods against for finding/generating obj
      #   debug_name: Name string to print in informational/diagnostic/debug messages
      class CMObjBase
        # lookup_by_id: Locate an entity by ID string
        # PRE:
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_id(obj, parent_obj, debug_name, id)
          if id.nil?
            fail "Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_id: ERROR: Passed nil id"
          end

          unless obj.nil?
            if obj.id == id
              Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_id: Existing object hit for #{id}")
              return obj
            end
          end

          obj = parent_obj.find { |sobj| sobj.id == id }
          if obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_id: No object found for #{id}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_id: New object found for #{id}")
          end

          return obj
        end

        # lookup_by_label: Lookup a check by label
        # PRE: none
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_label(obj, parent_obj, debug_name, label)
          if label.nil?
            fail "Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_label: ERROR: Passed nil label"
          end

          unless obj.nil?
            if obj.label == label
              Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_label: Existing object hit for #{label}")
              return obj
            end
          end

          obj = parent_obj.find { |sobj| sobj.label == label }
          if obj.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_label: No object found for #{label}")
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi(#{debug_name}).lookup_by_id: New object found for #{label}.  ID: #{obj.id}")
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
          if @obj.nil?
            return false
          end

          @obj.destroy
          return true
        end
      end # END CMApi class

      # CMEntity: Class handling entity operations
      class CMEntity < CMObjBase
        # initialize: initialize the class
        # PRE: credentials is a CMCredentials instance, my_chef_label is unique for this entity
        # POST: None
        # RETURN VALUE: None
        def initialize(credentials, my_chef_label)
          # This class intentionally uses a class method to share entity IDs across class instances
          # The class variable is guarded by use of the CMCache class which ensures IDs are utilized
          #    properly across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars

          @chef_label = my_chef_label
          @cm = CMApi.new(credentials).cm
          @username = credentials.get_attribute(:username)

          # Reuse an existing entity from our local cache, if present
          unless defined? @@entity_cache
            @@entity_cache = CMCache.new(2)
          end
          @entity_obj = @@entity_cache.get(@username, @chef_label)
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
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMEntity._update_entity_obj: Caching entity with ID #{new_entity.id}")
            @@entity_cache.save(@entity_obj, @username, @chef_label) # rubocop:disable ClassVars
                                                                     # See comment in constructor
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

          return _update_entity_obj(@cm.entities.find { |entity| _lookup_entity_by_ip_checker(entity, ip) })
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
          orig_obj = @entity_obj # rubocop:disable UselessAssignment
                                 # rubocop falsely flags this as useless, it's used via interpolation in the info log
          if obj_delete(@entity_obj, @cm.entities, 'Entity')
            _update_entity_obj(nil)
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMEntity.delete: Deleted entity #{@orig_obj.label} (#{@orig_obj.id})")
            return true
          end
          return false
        end
      end # END CMEntity class

      # CMChild class: This is a generic class to be inherited for checks and alarms
      # as the two are handled amlost identically
      class CMChild < CMObjBase
        # initialize: initialize the class
        # PRE: credentials is a CMCredentials instance, my_label is unique for this entity
        # POST: None
        # RETURN VALUE: None
        def initialize(credentials, entity_chef_label, my_target_name, my_debug_name, my_label)
          # This class intentionally uses a class method to share object IDs across class instances
          # The class variable is guarded by use of the CMCache class which ensures IDs are utilized
          #    properly across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars

          @target_name = my_target_name
          @debug_name = my_debug_name
          @entity_chef_label = entity_chef_label

          @entity = CMEntity.new(credentials, entity_chef_label)
          if @entity.entity_obj.nil?
            fail "Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).initialize: Unable to lookup entity with Chef label #{entity_chef_label}"
          end

          @username = credentials.get_attribute(:username)
          @label = my_label
          unless defined? @@obj_cache
            @@obj_cache = CMCache.new(4)
          end
          @obj = @@obj_cache.get(@username, @entity_chef_label, @target_name, @label)
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
        def _update_obj(new_entity)
          @obj = new_entity

          unless new_entity.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name})._update_obj: Caching entity with ID #{new_entity.id}")
            @@obj_cache.save(@obj, @username, @entity_chef_label, @target_name, @label)  # rubocop:disable ClassVars
                                                                                         # See comment in constructor
          end

          return new_entity
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
          orig_obj = obj # rubocop:disable UselessAssignment
                         # rubocop falsely flags this as useless, it's used via interpolation in the info log
          if obj_delete(@obj, _get_target, @target_name)
            _update_obj(nil)

            entity_id = @entity.entity_obj_id

            # Disable long line warnings for the info logs, no simple way to shorten them
            # rubocop:disable LineLength
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMChild(#{@debug_name}).delete: Deleted #{@debug_name} #{@orig_obj.label} (#{@orig_obj.id})[Entity #{@entity_chef_label}(#{entity_id})]")
            # rubocop:enable LineLength

            return true
          end
          return false
        end
      end # END CMChild class

      # CMCheck: Class for handling Cloud Monitoring Check objects
      class CMCheck < CMChild
        # Note that this initializer DOES NOT LOAD ANY CHECKS!
        # User must call a lookup function before calling update
        def initialize(credentials, entity_label, my_label)
          super(credentials, entity_label, 'checks', 'Check', my_label)
        end
      end

      # CMAlarm: Class for handling Cloud Monitoring Alarm objects
      class CMAlarm < CMChild
        # Note that this initializer DOES NOT LOAD ANY ALARMS!
        # User must call a lookup function before calling update
        def initialize(credentials, entity_label, my_label)
          super(credentials, entity_label, 'alarms', 'Alarm', my_label)
          @credentials = credentials
        end

        # get_credentials: return the credentials used
        # PRE: None
        # POST: None
        # RETURN VALUE: CMCredentials class
        # This is a *bit* of a hack as @credentials was originially saved in case get_example_alarm was called
        # which needs a cm object and should otherwise not be needed.  However, it makes our life slightly easier
        # in the alarm LWRP as we can use it to pass to the CMCheck constructor to get the check ID.
        def credentials
          return @credentials
        end

        # example_alarm: Look up an alarm definition from the example API and return its criteria
        # This does not modify the current alarm object, but it does require the inherited CMApi class
        # PRE: None
        # POST: None
        # Return Value: bound_criteria string
        def example_alarm(example_id, example_values)
          @cm = CMApi.new(@credentials).cm
          return @cm.alarm_examples.evaluate(example_id, example_values).bound_criteria
        end
      end

      # CMAgentToken: Class for handling Cloud Monitoring Agent Token objects
      class CMAgentToken < CMObjBase
        def initialize(credentials, token, label)
          @cm = CMApi.new(credentials).cm
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
        def delete_
          orig_obj = obj # rubocop:disable UselessAssignment
                         # rubocop falsely flags this as useless, it's used via interpolation in the info log
          if obj_delete(@obj, @cm.agent_tokens, @target_name)
            @obj = nil
            Chef::Log.info("Opscode::Rackspace::Monitoring::CMAgentToken.delete: Deleted token #{@orig_obj.id}")
            return true
          end
          return false
        end
      end # END CMAgentToken class
    end # END MODULE
  end
end
