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
          
          apikey   = _cm_attribute_logic(defined?(new_resource) ? new_resource.rackspace_api_key : nil,  node[:rackspace_cloudmonitoring][:api_key],  creds['apikey'])
          username = _cm_attribute_logic(defined?(new_resource) ? new_resource.rackspace_username : nil, node[:rackspace_cloudmonitoring][:username], creds['username'])
          auth_url = _cm_attribute_logic(defined?(new_resource) ? new_resource.rackspace_auth_url : nil, node[:rackspace_cloudmonitoring][:auth_url], creds['auth_url'])
          
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
      
      class CM_check < CM_entity
        # Note that this initializer DOES NOT LOAD ANY CHECKS!
        # User must call a lookup function to set check-update
        def initialize()
          @id_cache = CM_cache.new('check_ids', true)
          @check_obj = nil
        end

        # get_check_obj: Returns the check object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Check object or nil
        def get_check_obj
            return @check_obj
        end
        
        # lookup_check_by_label: Lookup a check by label, utilizing the cache
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Check object
        # THis is separate from the initializer to allow modifications to the @entity_obj
        def lookup_check_by_label(label)
          cached_id = @id_cache.get(label)
          if !cached_id.nil?
            @check_obj = get_entity_obj().checks.find{ |check| check.id==cached_id}
            if !@check_obj.nil?
              return
            end
          end

          @check_obj = get_entity_obj().checks.find{ |check| check.label==label}
          if !@check_obj.nil?
            @id_cache.save(@check_obj.id, label)
          end

          return @check_obj
        end

        # _update_check_obj: helper function to update @check_obj, update the ID cache, and help keep the code DRY
        # PRE: new_check is a valid Fog::Rackspace::Monitoring::Check object
        # POST: None
        # RETURN VALUE: new_entity
        def _update_check_obj(new_check)
          @check_obj = new_check
          @id_cache.set(new_check.id, label)
          return new_check
        end

        # update_check: Update or create a new monitoring check
        # PRE: @cache_obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update_check(attributes = {})
          new_check = get_entity_obj().checks.new(attributres)
          if @cache_obj.nil?
            new_check.save
            _update_check_obj(new_check)
            return true
          end

          new_check.id = @check_obj.id
          # Compare attributes
          if !new_check.compare? @check_obj then
            # It's different
            new_check.save
            _update_check_obj(new_check)
            return true
          end

          return false
        end
      end # END CM_check class
      
      class CM_alarm < CM_entity
        # TODO: THis is **almost** identical to CM_check
        # THis code should be dried out better
        def initialize(label)
          @id_cache = CM_cache.new('alarm_ids', true)
          @alarm_obj = nil
        end

        # get_alarm_obj: Returns the alarm object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::Alarm object or nil
        def get_alarm_obj
            return @alarm_obj
        end
        
        # lookup_alarm_by_label: Lookup a check by label, utilizing the cache
        # PRE: none
        # POST: None
        # RETURN VALUE: a Fog::Rackspace::Monitoring::Alarm object
        # THis is separate from the initializer to allow modifications to the @entity_obj
        def lookup_alarm_by_label(label)
           cached_id = @id_cache.get(label)
          if !cached_id.nil?
            @alarm_obj = get_entity_obj().alarms.find{ |alarm| alarm.id==cached_id}
            if !@alarm_obj.nil?
              return
            end
          end
          
          @alarm_obj = get_entity_obj().alarms.find{ |alarm| alarm.label==label}
          if !@alarm_obj.nil?
            @id_cache.save(@alarm_obj.id, label)
          end

          return @alarm_obj
        end
          
        # _update_alarm_obj: helper function to update @alarm_obj, update the ID cache, and help keep the code DRY
        # PRE: new_alarm is a valid Fog::Rackspace::Monitoring::Alarm object
        # POST: None
        # RETURN VALUE: new_entity
        def _update_alarm_obj(new_alarm)
          @alarm_obj = new_alarm
          @id_cache.set(new_alarm.id, label)
          return new_alarm
        end

        # update_alarm: Update or create a new monitoring alarm
        # PRE: @cache_obj has been looked up and set for updating existing entities
        # POST: None
        # RETURN VALUE: Returns true if the entity was updated, false otherwise
        # Idempotent: Does not update entities unless required
        def update_alarm(attributes = {})
          new_alarm = get_entity_obj().alarms.new(attributres)
          if @cache_obj.nil?
            new_alarm.save
            _update_alarm_obj(new_alarm)
            return true
          end

          new_alarm.id = @alarm_obj.id
          # Compare attributes
          if !new_alarm.compare? @alarm_obj then
            # It's different
            new_alarm.save
            _update_alarm_obj(new_alarm)
            return true
          end

          return false
        end
      end # END CM_alarm class

      
      class CM_tokens < CM_api
        def initialize(label)
          @id_cache = CM_cache.new('agent_id')
          cached_id = @id_cache.get
          if !cached_id.nil?
            @agent_obj = get_cm().agent_tokens.find{ |agent| agent.id==cached_id}
            if !@agent_obj.nil?
              return
            end
          end

          @agent_obj = get_cm().agent_tokens.find{ |agent| agent.label==label}
          if !@agent_obj.nil?
            @id_cache.set(@agent_obj.id)
          end
        end
          

        # get_token_obj: Returns the token object
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring::AgentToken object or nil
        def get_token_obj
          return @token_obj
        end
      end # END CM_tokens class


      # END Module
    end
  end
end
