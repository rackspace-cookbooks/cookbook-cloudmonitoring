include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.update(:label => new_resource.label))
end


action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.delete())
end

def load_current_resource
  @current_resource = CM_agent_token(@new_resource.token, @new_resource.label)
end
