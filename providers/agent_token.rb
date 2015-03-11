include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  agent_token = cm.agent_tokens.new(label: new_resource.label)
  if @current_resource.nil?
    Chef::Log.info("Creating #{new_resource}")
    agent_token.save
    new_resource.updated_by_last_action(true)
    clear_tokens
    if @new_resouce.label == node['cloud_monitoring']['agent']['id']
      Chef::Log.debug("Updating agent token for #{new_resource.label}")
      node.set['cloud_monitoring']['agent']['token'] = get_token_by_label(@new_resource.label).token
    end
  else
    Chef::Log.debug("#{new_resource} exists, skipping create")
    new_resource.updated_by_last_action(false)
  end
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  if !@current_resource.nil?
    Chef::Log.info("Deleting #{new_resource}")
    @current_resource.destroy
    new_resource.updated_by_last_action(true)
    clear_tokens
  else
    Chef::Log.debug("#{new_resource} doesn't exist, skipping delete")
    new_resource.updated_by_last_action(false)
  end
end

def load_current_resource
  @current_resource = get_token_by_id @new_resource.token
  return unless @current_resource.nil?

  @current_resource = get_token_by_label @new_resource.label
  node.set['cloud_monitoring']['agent']['token'] = @current_resource.identity unless @current_resource.nil?
  node.set['cloud_monitoring']['agent']['id'] = @current_resource.label unless @current_resource.nil?
end
