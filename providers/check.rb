include Rackspace::CloudMonitoring

action :create do
  check = @entity.checks.new(:label => new_resource.label, :type => new_resource.type, :details => new_resource.details,
                             :metadata => new_resource.metadata, :monitoring_zones_poll => new_resource.monitoring_zones_poll,
                             :target_alias => new_resource.target_alias, :target_hostname => new_resource.target_hostname,
                             :target_resolver => new_resource.target_resolver)
  if @current_resource.nil? then
    check.save
    new_resource.updated_by_last_action(true)
    clear
  else
    # Compare attributes
    if !check.compare? @current_resource then
      # It's different issue and update
      check.id = @current_resource.id
      check.save
      new_resource.updated_by_last_action(true)
      clear
    else
      new_resource.updated_by_last_action(false)
    end
  end
end


def load_current_resource
  @entity = get_entity_by_id @new_resource.entity_id || node[:cloud_monitoring][:entity_id]
  @current_resource = get_check_by_id @entity.id, node[:cloud_monitoring][:checks][@new_resource.name]
  if @current_resource == nil then
    @current_resource = get_check_by_name @entity.id, @new_resource.name
    node.set[:cloud_monitoring][:checks][@new_resource.name] = @current_resource.identity unless @current_resource.nil?
  end
end
