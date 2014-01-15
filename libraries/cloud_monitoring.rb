module Opscode
  module Rackspace
    module Monitoring
      require 'fog'
      
      # cm_api:  This class contains all the methods we use to access the Cloud Monitoring API
      class CM_api
        # Initialize: Initialize the class
        # Opens connections to the API via Fog, will share connections when possible
        # PRE: None
        # POST: None
        # RETURN VALUE: None
        # Opens @@cm class variable
        def initialize()
          # Utilize a class variable to only open one Fog connection
          if defined?(@@cm)
            if !@@cm.nil?
              return
            end
          end

          # This is a simple helper method to deduplicate precedence logic code
          def _cm_attribute_logic(resource, node, databag)
            # Precedence:
            # 1) new_resource variables (If available)
            # 2) Node data
            # 3) Data bag
            if argument
              return argument
            end
            if resource
              return resource
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
            Chef::Log.error("Opscode::Rackspace::Monitoring::cm_api.initialize: ERROR: Unable to connect to Fog")
          end
        end

        # get_cm(): Getter for the @@cm class variable
        # PRE: Class initialized
        # POST: none
        # RETURN VALUE: Fog::Rackspace::Monitoring class
        def get_cm()
          return @@cm
        end
      end          
      # END CM_api class

      # CM_cache: Class to handle caching IDs into the node attributes in a standard fashion
      class CM_cache
        # Initialize: Initialize our namespace
        # key is the unique key for this cache
        # enable_id enables a internal hash and enables id on the getters and setters
        def initialize(key, enable_id = false)
          @cache_key = key
          @id_enabled = enable_id

          # Verify this cache exists
          # As this isn't intended to be user exposed, this allows us to not need to show it in attributes.rb
          if node[:rackspace_cloudmonitoring][:cm_cache].nil?
            node.set[:rackspace_cloudmonitoring][:cm_cache] = {}
          end
          
          # Initialization here is only needed for multi-id caches (hashes)
          if @id_enabled
              if node[:rackspace_cloudmonitoring][:cm_cache][@cache_key].nil?
                # Initialize our cache
                node.set[:rackspace_cloudmonitoring][:cm_cache][@cache_key] = {}
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
                Chef::Log.error("Opscode::Rackspace::Monitoring::cm_cache.get: ERROR: id unspecified on a id enabled cache")
              end

              return node[:rackspace_cloudmonitoring][:cm_cache][@cache_key][id]
            else
              return node[:rackspace_cloudmonitoring][:cm_cache][@cache_key]
            end
        end

        # set: Set a value into our cache
        # PRE: Class initialized
        # POST: None
        # RETURN VALUE: None
        def set(value, id = nil)
            if @id_enabled
              if id.nil?
                Chef::Log.error("Opscode::Rackspace::Monitoring::cm_cache.get: ERROR: id unspecified on a id enabled cache")
              end
              
              Chef::Log.info("Updating cache entry [#{@cache_key}][#{id}] to #{value}")
              node.set[:rackspace_cloudmonitoring][:cm_cache][@cache_key][id] = value
            else
              Chef::Log.info("Updating cache entry [#{@cache_key}] to #{value}")
              node.set[:rackspace_cloudmonitoring][:cm_cache][@cache_key] = value
            end
        end
      end
      # END CM_cache class

      # cm_entity: Class handling entity operations
      class CM_entity < CM_api
        def initialize()
          super

          @id_cache = CM_cache.new('entity_id')
          cached_id = @id_cache.get
          if !cached_id.nil?
            @entity_obj = get_cm().entities.find{ |entity| entity.id==@id_cache.get}
          else
            @entity_obj = nil
          end
        end
        
        # get_obj: Return the entity object
        # PRE: None
        # POST: None
        # Returns a Fog::Rackspace::Monitoring::Entity object or nil
        def get_entity_obj
          return @entity_obj
        end
        
        # get_obj_id: Return the entity object id
        # PRE: None
        # POST: None
        # Returns a string or nil
        def get_entity_obj_id
          if @entity_obj.nil?
            return nil
          end
          
          return @entity_obj.id
        end
        
        # _update_entity_obj: helper function to update @entity_obj, update the ID cache, and help keep the code DRY
        # PRE: new_entity is a valid Fog::Rackspace::Monitoring::Entity object
        # POST: None
        # RETURN VALUE: new_entity
        def _update_entity_obj(new_entity)
          @entity_obj = new_entity
          @id_cache.set(new_entity.id)
          return new_entity
        end
        
        # lookup_entity_by_id: Locate an entity by ID string
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_id(id)
          if !@entity_obj.nil?
            if @entity_obj.id == id
              return @entity_obj
            end
          end

          return _update_entity_obj(get_cm().entities.find{ |entity| entity.id==id})
        end
        
        # lookup_entity_by_label: Locate an entity by label string
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Entity object or Nil
        # Sets @entity_obj
        def lookup_entity_by_label(label)
          if !@entity_obj.nil?
            if @entity_obj.label == label
              return @entity_obj
            end
          end

          return _update_entity_obj(get_cm().entities.find{ |entity| entity.label==label})
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
          new_entity = get_cm().entities.new(attributes)
          if @entity_obj.nil?
            new_entity.save
            _update_entity_obj(new_entity)
            return true
          end

          new_entity.id = @entity_obj.id
          # Compare attributes
          if !new_entity.compare? @entity_obj then
            # It's different
            new_entity.save
            _update_entity_obj(new_entity)
            return true
          end
          
          return false
        end

        # delete_entity: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_entity()
          if @entity_obj.nil?
            return false
          end

          @entity_obj.destroy
          _update_entity_obj(nil)
          return true
        end

      end # END CM_entity class


      # CM_Child class: This is a generic class to be inherited for checks and alarms
      # as the two are handled amlost identically
      class CM_child < CM_entity
        def initialize(my_target_name)
          super
          @obj = nil
          @target_name = my_target_name
        end

        # _get_target: Call send on the entity to get the target object
        # PRE: get_entity_obj() PRE conditions met
        # POST: None
        # Return Value: Target Object
        def _get_target
          return get_entity_obj().send(@target_name)
        end

        # get_obj: Returns the check object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Check object or nil
        def get_obj
          return @obj
        end
        
        # lookup_by_label: Lookup a check by label
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        # This is separate from the initializer to allow modifications to the @entity_obj
        def lookup_by_label(label)
          if !@obj.nil?
            if @obj.label == label
              return @obj
            end
          end
              
          @obj = _get_target().find{ |i| i.label==label}
        end

        # update: Update or create a new object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update(attributes = {})
          new_obj = _get_target().new(attributres)
          if @obj.nil?
            new_obj.save
            @obj = new_obj
            return true
          end

          new_obj.id = @obj.id
          # Compare attributes
          if !new_obj.compare? @obj then
            # It's different
            new_obj.save
            @obj = new_obj
            return true
          end

          return false
        end
      end # END CM_child class

      class CM_check < CM_child
        # Note that this initializer DOES NOT LOAD ANY CHECKS!
        # User must call a lookup function before calling update
        def initialize()
          super(:checks)
        end
      end
      
      class CM_alarm < CM_child
        # Note that this initializer DOES NOT LOAD ANY ALARMS!
        # User must call a lookup function before calling update
        def initialize()
          super(:alarms)
        end
      end
        
      class CM_agent_token < CM_api
        # This does not inherit from CM_child as it doesn't use an entity.
        # Otherwise it is very similar.
        def initialize(token, label)
          if not token.nil?
            @obj = get_cm().agent_tokens.find{ |agent| agent.id==token}
            if !@obj.nil?
              return
            end
          end

          @obj = get_cm().agent_tokens.find{ |agent| agent.label==label}
        end
          
        # get_obj: Returns the token object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::AgentToken object or nil
        def get_obj
          return @obj
        end

        # update: Update or create a new token object
        # PRE: @obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update(attributes = {})
          new_obj = get_cm().agent_tokens.new(attributres)
          if @obj.nil?
            new_obj.save
            @obj = new_obj
            return true
          end

          new_obj.id = @obj.id
          # Compare attributes
          if !new_obj.compare? @obj then
            # It's different
            new_obj.save
            @obj = new_obj
            return true
          end
          
          return false
        end

        # delete: does what it says on the tin
        # PRE: None
        # POST: None
        # RETURN VALUE: Returns true if the entity was deleted, false otherwise
        def delete_entity()
          if @obj.nil?
            return false
          end

          @obj.destroy
          @obj = nil
          return true
        end
      end # END CM_tokens class

    end # END MODULE
  end
end
