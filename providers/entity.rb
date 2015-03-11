include Opscode::Rackspace::Monitoring

require 'ipaddr'

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  # normalize the ip's
  if new_resource.ip_addresses
    new_ips = {}
    new_resource.ip_addresses.each { |k, v| new_ips[k] = IPAddr.new(v).to_string }
    new_resource.ip_addresses.update new_ips
  end
  entity = cm.entities.new(
    label: new_resource.label,
    ip_addresses: new_resource.ip_addresses,
    metadata: new_resource.metadata,
    agent_id: new_resource.agent_id
  )
  if @current_resource.nil?
    Chef::Log.info("Creating #{new_resource}")
    entity.save
    new_resource.updated_by_last_action(true)
    update_node_entity_id(entity.id)
    update_node_agent_id((new_resource.agent_id || new_resource.label))
    clear
  else
    # Compare attributes
    if !entity.compare? @current_resource
      # It's different
      Chef::Log.info("Updating #{new_resource}")
      entity.id = @current_resource.id
      entity.save
      new_resource.updated_by_last_action(true)
      clear
    else
      Chef::Log.debug("#{new_resource} matches, skipping")
      new_resource.updated_by_last_action(false)
    end
  end
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  if !@current_resource.nil?
    @current_resource.destroy
    new_resource.updated_by_last_action(true)
    clear
  else
    new_resource.updated_by_last_action(false)
  end
end

def load_current_resource
  @current_resource = get_entity_by_id node['cloud_monitoring']['entity_id']
  return unless @current_resource.nil?

  @current_resource = get_entity_by_label @new_resource.label
  update_node_entity_id(@current_resource.identity) unless @current_resource.nil?
  update_node_agent_id((@current_resource.agent_id || @current_resource.label)) unless @current_resource.nil?
end
