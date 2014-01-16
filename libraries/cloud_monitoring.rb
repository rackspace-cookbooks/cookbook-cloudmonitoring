module Opscode
  module Rackspace
    module Monitoring
      # cm_api:  This class initializes the connection to the Cloud Monitoring API
      class CM_api
        # Initialize: Initialize the class
        # Opens connections to the API via Fog, will share connections when possible
        # PRE: None
        # POST: None
        # RETURN VALUE: None
        # Opens @@cm class variable
        def initialize(node)
          # Utilize a class variable to only open one Fog connection
          if defined?(@@cm)
            if !@@cm.nil?
              Chef::Log.debug("Opscode::Rackspace::Monitoring::cm_api.initialize: Reusing existing Fog connection")
              return
            end
          end

          # This is a simple helper method to deduplicate precedence logic code
          def _cm_attribute_logic(resource, node, databag)
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

          # @@cm is uninitialized, open the connection to Fog
          begin
            # Access the Rackspace Cloud encrypted data_bag
            creds = Chef::EncryptedDataBagItem.load(
                                                    node[:rackspace_cloudmonitoring]["credentials"]["databag_name"],
                                                    node[:rackspace_cloudmonitoring]["credentials"]["databag_item"]
                                                    )
          rescue Exception => e
            creds = {'username' => nil, 'apikey' => nil, 'auth_url' => nil }
          end

          apikey   = _cm_attribute_logic(defined?(new_resource) ? new_resource.rackspace_api_key : nil,  node[:rackspace_cloudmonitoring][:rackspace_api_key],  creds['apikey'])
          username = _cm_attribute_logic(defined?(new_resource) ? new_resource.rackspace_username : nil, node[:rackspace_cloudmonitoring][:rackspace_username], creds['username'])
          auth_url = _cm_attribute_logic(defined?(new_resource) ? new_resource.rackspace_auth_url : nil, node[:rackspace_cloudmonitoring][:rackspace_auth_url], creds['auth_url'])

          Chef::Log.debug("Opscode::Rackspace::Monitoring::cm_api.initialize: creating new Fog connection")
          @@cm = Fog::Rackspace::Monitoring.new(
                                                :rackspace_api_key => apikey,
                                                :rackspace_username => username,
                                                :rackspace_auth_url => auth_url
                                                )

          if @@cm.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::cm_api.initialize: ERROR: Unable to connect to Fog"
          end
          Chef::Log.debug("Opscode::Rackspace::Monitoring::cm_api.initialize: Fog connection successful")

        end

        # get_cm(): Getter for the @@cm class variable
        # PRE: Class initialized
        # POST: none
        # RETURN VALUE: Fog::Rackspace::Monitoring class
        def get_cm()
          return @@cm
        end

        #
        # Common methods for interacting with MaaS Objects
        #

        # lookup_by_id: Locate an entity by ID string
        # PRE:
        # POST: None
        # RETURN VALUE: returns looked up obj
        def obj_lookup_by_id(obj, parent_obj, debug_name, id)
          if id.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_Api(#{debug_name}).lookup_by_id: ERROR: Passed nil id"
            return nil
          end

          if !obj.nil?
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

          if !obj.nil?
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
          if !new_obj.compare? obj then
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

      # CM_cache: Class to handle caching IDs into the node attributes in a standard fashion
      class CM_cache
        # Initialize: Initialize our namespace
        # key is the unique key for this cache
        # enable_id enables a internal hash and enables id on the getters and setters
        def initialize(node, key, enable_id = false)
          @cache_key = key
          @id_enabled = enable_id
          @node = node

          # Verify this cache exists
          # As this isn't intended to be user exposed, this allows us to not need to show it in attributes.rb
          if @node[:rackspace_cloudmonitoring][:cm_cache].nil?
            @node.set[:rackspace_cloudmonitoring][:cm_cache] = {}
          end

          # Initialization here is only needed for multi-id caches (hashes)
          if @id_enabled
              if @node[:rackspace_cloudmonitoring][:cm_cache][@cache_key].nil?
                # Initialize our cache
                @node.set[:rackspace_cloudmonitoring][:cm_cache][@cache_key] = {}
              end
          end
        end

        # get: Get a value from our cache
        # PRE: Class initialized
        # POST: None
        # RETURN VALUE: Cache content
        def get(id = nil)
            if @id_enabled
              if id.nil?
                raise Exception, "Opscode::Rackspace::Monitoring::cm_cache.get: ERROR: id unspecified on a id enabled cache"
              end

              return @node[:rackspace_cloudmonitoring][:cm_cache][@cache_key][id]
            else
              return @node[:rackspace_cloudmonitoring][:cm_cache][@cache_key]
            end
        end

        # set: Set a value into our cache
        # PRE: Class initialized
        # POST: None
        # RETURN VALUE: None
        def set(value, id = nil)
            if @id_enabled
              if id.nil?
                raise Exception, "Opscode::Rackspace::Monitoring::cm_cache.get: ERROR: id unspecified on a id enabled cache"
              end

              Chef::Log.info("Updating cache entry [#{@cache_key}][#{id}] to #{value}")
              @node.set[:rackspace_cloudmonitoring][:cm_cache][@cache_key][id] = value
            else
              Chef::Log.info("Updating cache entry [#{@cache_key}] to #{value}")
              @node.set[:rackspace_cloudmonitoring][:cm_cache][@cache_key] = value
            end
        end
      end
      # END CM_cache class

      # cm_entity: Class handling entity operations
      class CM_entity < CM_api
        def initialize(node)
          super(node)

          @id_cache = CM_cache.new(node, 'entity_id')
          cached_id = @id_cache.get
          if !cached_id.nil?
            @entity_obj = obj_lookup_by_id(nil, get_cm().entities, "Entity", cached_id)
          else
            @entity_obj = nil
          end
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
            return "nil"
          end

          return "Entity #{@entity_obj.label} (#{@entity_obj.id})"
        end

        # _update_entity_obj: helper function to update @entity_obj, update the ID cache, and help keep the code DRY
        # PRE: new_entity is a valid Fog::Rackspace::Monitoring::Entity object
        # POST: None
        # RETURN VALUE: new_entity
        def _update_entity_obj(new_entity)
          @entity_obj = new_entity

          if not new_entity.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_entity._update_entity_obj: Caching entity with ID #{new_entity.id}")
            @id_cache.set(new_entity.id)
          else
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CM_entity._update_entity_obj: Caching EMPTY Entity")
          end

          return new_entity
        end

        # lookup_entity_by_id: Locate an entity by ID string
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_id(id)
          return _update_entity_obj(obj_lookup_by_id(@entity_obj, get_cm().entities, "Entity", id))
        end

        # lookup_entity_by_label: Locate an entity by label string
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_label(label)
          return _update_entity_obj(obj_lookup_by_label(@entity_obj, get_cm().entities, "Entity", label))
        end

        # lookup_entity_by_ip: Locate an entity by IP address
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_ip(ip)
          # Search helper function
          def _lookup_entity_by_ip_checker ( entity, tgtip )
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
            raise Exception, "Opscode::Rackspace::Monitoring::CM_entity.lookup_entity_by_ip: ERROR: Passed nil ip"
          end

          if !@entity_obj.nil?
            if _lookup_entity_by_ip_checker(@entity_obj, ip)
              return @entity_obj
            end
          end

          return _update_entity_obj(get_cm().entities.find{ |entity| _lookup_entity_by_ip_checker(entity, ip)})
        end

        # update_entity: Update or create a new monitoring entity
        # PRE: @entity_obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update_entity(attributes = {})
          orig_obj = @entity_obj
          _update_entity_obj(obj_update(@entity_obj, get_cm().entities, "Entity", attributes))

          if orig_obj.nil?
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_entity.update_entity: Created new entity #{@entity_obj.label} (#{@entity_obj.id})")
            return true
          end

          if !@entity_obj.compare? orig_obj
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_entity.update_entity: Updated entity #{@entity_obj.label} (#{@entity_obj.id})")
            return true
          end

          return false
        end

        # delete_entity: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_entity()
          orig_obj = @entity_obj
          if obj_delete(@entity_obj, get_cm().entities, "Entity")
            _update_entity_obj(nil)
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_entity.delete: Deleted entity #{@orig_obj.label} (#{@orig_obj.id})")
            return true
          end
          return false
        end

      end # END CM_entity class

      # CM_Child class: This is a generic class to be inherited for checks and alarms
      # as the two are handled amlost identically
      class CM_child < CM_entity
        def initialize(node, my_target_name, my_debug_name)
          super(node)
          @obj = nil

          @target_name = my_target_name
          @debug_name = my_debug_name
        end
        
        # _get_target: Call send on the entity to get the target object
        # PRE: get_entity_obj() PRE conditions met
        # POST: None
        # Return Value: Target Object
        def _get_target
          entity_id = get_entity_obj()
          if entity_id.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_child(#{@debug_name})._get_target: ERROR: nil entity"
          end

          return get_entity_obj().send(@target_name)
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
            return "nil"
          end

          entity_id = get_entity_obj_id()
          return "#{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{entity_id}]"
        end

        # lookup_by_id: Lookup a child by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        # This is separate from the initializer to allow modifications to the @entity_obj
        def lookup_by_id(id)
          @obj = obj_lookup_by_id(@obj, _get_target(), @debug_name, id)
          return @obj
        end

        # lookup_by_label: Lookup a child by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        # This is separate from the initializer to allow modifications to the @entity_obj
        def lookup_by_label(label)
          @obj = obj_lookup_by_label(@obj, _get_target(), @debug_name, label)
          return @obj
        end

        # update: Update or create a new object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update(attributes = {})
          orig_obj = @obj
          @obj = obj_update(@obj, _get_target(), @debug_name, attributes)
          if @obj.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).update: obj_update returned nil"
          end

          if orig_obj.nil?
            entity_id = get_entity_obj_id()
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).update: Created new #{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{entity_id}]")
            return true
          end
            
          if !@obj.compare? orig_obj
            entity_id = get_entity_obj_id()
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).update: Updated #{@debug_name} #{@obj.label} (#{@obj.id})[Entity #{entity_id}]")
            return true
          end

          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete()
          orig_obj = obj
          if obj_delete(@obj, _get_target(), @target_name)
            _update_entity_obj(nil)

            entity_id = get_entity_obj_id()
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_child(#{@debug_name}).delete: Deleted #{@debug_name} #{@orig_obj.label} (#{@orig_obj.id})[Entity #{entity_id}]")
            return true
          end
          return false
        end
      end # END CM_child class

      class CM_check < CM_child
        # Note that this initializer DOES NOT LOAD ANY CHECKS!
        # User must call a lookup function before calling update
        def initialize(node)
          super(node, :checks, "Check")
        end
      end

      class CM_alarm < CM_child
        # Note that this initializer DOES NOT LOAD ANY ALARMS!
        # User must call a lookup function before calling update
        def initialize(node)
          super(node, :alarms, "Alarm")
        end

        # get_example_alarm: Look up an alarm definition from the example API and return its criteria
        # This does not modify the current alarm object, but it does require the inherited CM_api class
        # PRE: None
        # POST: None
        # Return Value: bound_criteria string
        def get_example_alarm(example_id, example_values)
          return get_cm().alarm_examples.evaluate(example_id, example_values).bound_criteria
        end
      end

      class CM_agent_token < CM_api
        # This does not inherit from CM_child as it doesn't use an entity.
        # Otherwise it is very similar.
        def initialize(node, token, label)
          super(node)

          if not token.nil?
            @obj = obj_lookup_by_id(nil, get_cm().agent_tokens, "Agent_Token", token)
            if !@obj.nil?
              return
            end
          end

          if label.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_agent_token.initialize: ERROR: Passed nil label"
          end

          @obj = obj_lookup_by_label(nil, get_cm().agent_tokens, "Agent_Token", label)
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
            return "nil"
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
          @obj = obj_update(@obj, get_cm().agent_tokens, "Agent_Token", attributes)
          if @obj.nil?
            raise Exception, "Opscode::Rackspace::Monitoring::CM_agent_token.update obj_update returned nil"
          end

          if orig_obj.nil?
            entity_id = get_entity_obj_id()
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_agent_token.update: Created new agent token #{@obj.id}")
            return true
          end
            
          if !@obj.compare? orig_obj
            entity_id = get_entity_obj_id()
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_agent_token.update: Updated agent token #{@obj.id}")
            return true
          end

          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_entity()
          orig_obj = obj
          if obj_delete(@obj, _get_target(), @target_name)
            _update_entity_obj(nil)

            entity_id = get_entity_obj_id()
            Chef::Log.info("Opscode::Rackspace::Monitoring::CM_agent_token.delete: Deleted token #{@orig_obj.id}")
            return true
          end
          return false
        end
      end # END CM_tokens class

    end # END MODULE
  end
end
