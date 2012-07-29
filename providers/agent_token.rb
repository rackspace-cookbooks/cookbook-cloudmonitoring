include Rackspace::CloudMonitoring

action :create do
  agent_token = cm.agent_tokens.new(:label => new_resource.label)
  if @current_resource.nil? then
    agent_token.save
    new_resource.updated_by_last_action(true)
    clear_tokens
  else
    new_resource.updated_by_last_action(false)
  end
end


action :delete do
  if !@current_resource.nil? then
    @current_resource.destroy
    new_resource.updated_by_last_action(true)
    clear_tokens
  else
    new_resource.updated_by_last_action(false)
  end
end


def load_current_resource
  @current_resource = get_token_by_id @new_resource.token
  if @current_resource == nil then
    @current_resource = get_token_by_label @new_resource.label
    node.set['cloud_monitoring']['agent']['token'] = @current_resource.identity unless @current_resource.nil?
  end
end
