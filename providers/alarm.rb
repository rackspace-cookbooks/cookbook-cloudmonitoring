include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  # run load_current_resource so that on the first run of the cookbook
  # the @entity methods do not throw errors
  if @entity.nil?
    # clear the view that keeps returning nil
    clear
    # reload the resource
    load_current_resource
  end
  criteria = new_resource.criteria
  check_id = new_resource.check_id

  if new_resource.example_id then
    raise Exception, "Cannot specify example_id and criteria" unless new_resource.criteria.nil?

    ae = cm.alarm_examples.evaluate(new_resource.example_id, new_resource.example_values)
    criteria = ae.bound_criteria
  end

  if new_resource.check_label then
    raise Exception, "Cannot specify check_label and check_id" unless new_resource.check_id.nil?
    check_id = get_check_by_label(@entity.id, new_resource.check_label).identity
  end

  notification_plan_id = new_resource.notification_plan_id || node['cloud_monitoring']['notification_plan_id']
  if notification_plan_id.nil? then
    raise ValueError, "Must specify 'notification_plan_id' in alarm resource or in node['cloud_monitoring']['notification_plan_id']"
  end

  alarm = @entity.alarms.new(
    :label => new_resource.label,
    :check_type => new_resource.check_type,
    :metadata => new_resource.metadata,
    :check => check_id,
    :criteria => criteria,
    :notification_plan_id => notification_plan_id
  )

  if @current_resource.nil? then
    Chef::Log.info("Creating #{new_resource}")
    alarm.save
    new_resource.updated_by_last_action(true)
    update_node_alarm(@new_resource.label,alarm.id)
    clear
  else
    # Compare attributes
    if !alarm.compare? @current_resource then
      # It's different issue and update
      Chef::Log.info("Updating #{new_resource}")
      alarm.id = @current_resource.id
      alarm.save
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

  @current_resource = get_alarm_by_id @entity.id, node['cloud_monitoring']['alarms'][@new_resource.label]
  if @current_resource == nil then
    @current_resource = get_alarm_by_label @entity.id, @new_resource.label
    update_node_alarm(@new_resource.label,@current_resource.identity) unless @current_resource.nil?
  end
end
