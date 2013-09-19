module Opscode
  module Rackspace
    module Monitoring

      def cm
        begin
          # Access the Rackspace Cloud encrypted data_bag
          creds = Chef::EncryptedDataBagItem.load(
            node["cloud_monitoring"]["credentials"]["databag_name"],
            node["cloud_monitoring"]["credentials"]["databag_item"]
          )
        rescue Exception => e
          creds = {'username' => nil, 'apikey' => nil, 'auth_url' => nil }
        end

        apikey = new_resource.rackspace_api_key || creds['apikey']
        username = new_resource.rackspace_username || creds['username']
        auth_url = new_resource.rackspace_auth_url || creds['auth_url']
        @@cm ||= Fog::Rackspace::Monitoring.new(
          :rackspace_api_key => apikey,
          :rackspace_username => username,
          :rackspace_auth_url => auth_url
        )

        @@view ||= Hash[@@cm.entities.overview.map {|x| [x.identity, x]}]
        @@cm
      end

      def tokens
        @@tokens ||= Hash[cm.agent_tokens.all.map {|x| [x.identity, x]}]
      end

      def clear
        @@view = nil
      end

      def clear_tokens
        @@tokens = nil
      end

      def view
        cm
        @@view
      end

      def update_node_entity_id(entity_id)
        node.set['cloud_monitoring']['entity_id'] = entity_id
        Chef::Log.info("Updating node entity id to #{entity_id}")
      end

      def update_node_agent_id(agent_id)
        node.set['cloud_monitoring']['agent']['id'] = agent_id
        Chef::Log.info("updating node agent id to #{agent_id}")
      end

      def update_node_check(label,check_id)
        node.set['cloud_monitoring']['check_id'][label] = check_id
        Chef::Log.info("updating check #{label} to #{check_id}")
      end

      def update_node_alarm(label, alarm_id)
        node.set['cloud_monitoring']['alarm_id'][label] = alarm_id
        Chef::Log.info("updating alarm #{label} to #{alarm_id}")
      end

      def get_type(entity_id, type)
        return {} if view[entity_id].nil?
        if type == 'checks' then
          view[entity_id].checks
        elsif type == 'alarms' then
          view[entity_id].alarms
        else
          raise Exception, "type #{type} not found."
        end
      end

      def get_child_by_id(entity_id, id, type)
        objs = get_type entity_id, type
        obj = objs.select { |x| x.identity === id }
        if !obj.empty? then
          obj.first
        else
          nil
        end

      end

      def get_child_by_label(entity_id, label, type)
        objs = get_type entity_id, type
        obj = objs.select {|x| x.label === label}
        if !obj.empty? then
          obj.first
        else
          nil
        end
      end

      #####
      # Specific objects
      def get_entity_by_id(id)
        view[id]
      end

      def get_entity_by_label(label)
        possible = view.select {|key, value| value.label === label}
        possible = Hash[*possible.flatten(1)]

        if !possible.empty? then
          possible.values.first
        else
          nil
        end
      end

      def get_entity_by_ip(ip_address)
        possible = view.select {|key, value| value.ip_addresses.has_value?(ip_address) }
        possible = Hash[*possible.flatten(1)]

        if !possible.empty? then
          possible.values.first
        else
          nil
        end
      end

      def get_check_by_id(entity_id, id)
        get_child_by_id entity_id, id, 'checks'
      end

      def get_check_by_label(entity_id, label)
        get_child_by_label entity_id, label, 'checks'
      end

      def get_alarm_by_id(entity_id, id)
        get_child_by_id entity_id, id, 'alarms'
      end

      def get_alarm_by_label(entity_id, label)
        get_child_by_label entity_id, label, 'alarms'
      end

      def get_token_by_id(token)
        tokens[token]
      end

      def get_token_by_label(label)
        possible = tokens.select {|key, value| value.label === label}
        possible = Hash[*possible.flatten(1)]

        if !possible.empty? then
          possible.values.first
        else
          nil
        end
      end
    end
  end
end
