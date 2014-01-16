include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  resource_updated = @current_resource.update(:label => new_resource.label)
  if resource_updated
    Chef::Log.info("Resource #{current_resource} updated")
  end
  new_resource.updated_by_last_action(resource_updated)
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  resource_updated = @current_resource.delete()
    if resource_updated
      Chef::Log.info("Resource #{current_resource} deleted")
  end
  new_resource.updated_by_last_action(resource_updated)
end

def load_current_resource
  @current_resource = CM_agent_token.new(node, @new_resource.token, @new_resource.label)
end
