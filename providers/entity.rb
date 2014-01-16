include Opscode::Rackspace::Monitoring

require 'ipaddr'

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  # normalize the ip's
  if new_resource.ip_addresses then
    new_ips = {}
    new_resource.ip_addresses.each {|k, v| new_ips[k] = IPAddr.new(v).to_string }
    new_resource.ip_addresses.update new_ips
  end
  
  resource_updated = @current_resource.update_entity(
    :label => new_resource.label,
    :ip_addresses => new_resource.ip_addresses,
    :metadata => new_resource.metadata,
    :agent_id => new_resource.agent_id
  )
  if resource_updated
    Chef::Log.info("Resource #{current_resource} updated")
  end
  new_resource.updated_by_last_action(resource_updated)

end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  resource_updated = @current_resource.delete_entity()
  if resource_updated
    Chef::Log.info("Resource #{current_resource} deleted")
  end
  new_resource.updated_by_last_action(resource_updated)
end


def load_current_resource
  @current_resource = CM_entity.new(node)
  Chef::Log.debug("Opscode::Rackspace::Monitoring::Entity #{new_resource} load_current_resource: Using search method #{new_resource.search_method}")
  case new_resource.search_method
  when 'ip'
    @current_resource.lookup_entity_by_ip(@new_resource.search_ip)
  when 'id'
    @current_resource.lookup_entity_by_id(@new_resource.id)
  else
    @current_resource.lookup_entity_by_label(@new_resource.label)
  end
end
