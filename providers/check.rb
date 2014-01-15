include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.update_check(
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
  ))
end


def load_current_resource
  @current_resource = CM_check.new
  
  # Configure the entity details, if specified
  if @new_resource.entity_label then
    raise Exception, "Cannot specify entity_label and entity_id" unless @new_resource.entity_id.nil?
    @current_resource.lookup_entity_by_label(@new_resource.entity_label)
  else
    if @new_resource.entity_id
      @current_resource.lookup_entity_by_id(@new_resource.entity_id)
    end
  end

  # Lookup the check
  @current_resource.lookup_check_by_label(@new_resource.label)
end
