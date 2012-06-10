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
  end
end
