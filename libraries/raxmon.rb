begin
  require 'rackspace-monitoring'
rescue LoadError
  Chef::Log.warn("Missing gem 'rackspace-monitoring'")
end

module Rackspace
  module CloudMonitoring

    def cm
      begin
        dbag = data_bag_item("cloud_monitoring", "main")
      rescue
        dbag = {:rackspace_api_key => nil, :rackspace_username => nil }
      end
      apikey = new_resource.rackspace_api_key || dbag[:rackspace_api_key]
      username = new_resource.rackspace_username || dbag[:rackspace_username]
      @@cm ||= Fog::Monitoring::Rackspace.new(:rackspace_api_key => apikey, :rackspace_username => username)
      @@view ||= Hash[@@cm.entities.overview.map {|x| [x.identity, x]}]
      @@cm
    end

    def clear
      @@view = nil
    end

    def view
      cm
      @@view
    end

    def get_entity_by_id(id)
      view[id]
    end

    def get_entity_by_name(name)
      possible = view.select {|key, value| value.label === name}
      if !possible.empty? then
        possible.values.first
      else
        nil
      end
    end

    def get_check_by_id(entity_id, id)
      chk = view[entity_id].checks.filter { |x| x.identity === id }
      if !chk.empty? then
        chk.first
      else
        nil
      end
    end

    def get_check_by_name(entity_id, name)
      possible = view[entity_id].checks.filter {|x| x.label === name}
      if !possible.empty? then
        possible.values.first
      else
        nil
      end
    end
  end
end
