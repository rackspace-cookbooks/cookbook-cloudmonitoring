include Opscode::Rackspace::Monitoring

action :create do
  check = @entity.checks.new(
    :label => new_resource.label,
    :type => new_resource.type,
    :details => new_resource.details,
    :metadata => new_resource.metadata, 
    :monitoring_zones_poll => new_resource.monitoring_zones_poll,
    :target_alias => new_resource.target_alias,
    :target_hostname => new_resource.target_hostname,
    :target_resolver => new_resource.target_resolver,
    :timeout => new_resource.timeout,
    :period => new_resource.period
  )
  if @current_resource.nil? then
    Chef::Log.info("Creating #{new_resource}")
    check.save
    new_resource.updated_by_last_action(true)
    clear
  else
    # Compare attributes
    if !check.compare? @current_resource then
      # It's different issue and update
      Chef::Log.info("Updating #{new_resource}")
      check.id = @current_resource.id
      check.save
      new_resource.updated_by_last_action(true)
      clear
    else
      Chef::Log.debug("#{new_resource} matches, skipping")
      new_resource.updated_by_last_action(false)
    end
  end
end


def load_current_resource
  if @new_resource.entity_label then
    raise Exception, "Cannot specify entity_label and entity_id" unless @new_resource.entity_id.nil?
    @entity = get_entity_by_label @new_resource.entity_label
  else
    @entity = get_entity_by_id @new_resource.entity_id || node['cloud_monitoring']['entity_id']
  end

  if @entity == nil
    @entity = get_entity_by_ip node['cloud']['public_ipv4']
  end

  @current_resource = get_check_by_id @entity.id, node['cloud_monitoring']['checks'][@new_resource.label]
  if @current_resource == nil then
    @current_resource = get_check_by_label @entity.id, @new_resource.label
    node.set['cloud_monitoring']['checks'][@new_resource.label] = @current_resource.identity unless @current_resource.nil?
  end
end