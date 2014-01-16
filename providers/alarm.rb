include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  criteria = new_resource.criteria
  check_id = new_resource.check_id

  if new_resource.example_id then
    raise Exception, "Cannot specify example_id and criteria" unless new_resource.criteria.nil?

    criteria = @current_resource.get_example_alarm(new_resource.example_id, new_resource.example_values)
  end

  if new_resource.check_label then
    raise Exception, "Cannot specify check_label and check_id" unless new_resource.check_id.nil?

    check_obj = CM_check.new(node)
    # Use the entity_id from our alarm class
    check_obj.lookup_entity_by_id(@current_resource.get_entity_obj_id)
    check_obj.lookup_by_label(new_resource.check_label)

    if check_obj.get_obj().nil?
      entity_id = @current_resource.get_entity_obj_id
      raise Exception, "Unable to lookup check #{new_resource.check_label} on entity #{entity_id}"
    end

    check_id = check_obj.get_obj().id
  end

  notification_plan_id = new_resource.notification_plan_id || node[:rackspace_cloudmonitoring]['notification_plan_id']
  if notification_plan_id.nil? then
    raise ValueError, "Must specify 'notification_plan_id' in alarm resource or in node[:rackspace_cloudmonitoring]['notification_plan_id']"
  end

  
  new_resource.updated_by_last_action(@current_resource.update(
    :label => new_resource.label,
    :check_type => new_resource.check_type,
    :metadata => new_resource.metadata,
    :check => check_id,
    :criteria => criteria,
    :notification_plan_id => notification_plan_id
  ))

end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.delete())
end

def load_current_resource
  @current_resource = CM_alarm.new(node)

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
  @current_resource.lookup_by_label(@new_resource.label)
end
