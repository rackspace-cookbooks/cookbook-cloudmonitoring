include Rackspace::CloudMonitoring

action :create do
  criteria = new_resource.criteria
  check_id = new_resource.check_id

  if new_resource.example_id then
    raise Exception, "Cannot specify example_id and criteria" unless new_resource.criteria.nil?

    ae = cm.alarm_examples.evaluate(new_resource.example_id, new_resource.example_values)
    criteria = ae.bound_criteria
  end

  if new_resource.check_name then
    raise Exception, "Cannot specify check_name and check_id" unless new_resource.check_id.nil?
    check_id = get_check_by_name(@entity.id, new_resource.check_name).identity
  end

  check = @entity.alarms.new(:label => new_resource.label, :check_type => new_resource.check_type, :check_id => check_id,
                             :metadata => new_resource.metadata, :criteria => criteria,
                             :notification_plan_id => new_resource.notification_plan_id)
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
  @current_resource = get_alarm_by_id @entity.id, node[:cloud_monitoring][:alarms][@new_resource.name]
  if @current_resource == nil then
    @current_resource = get_alarm_by_name @entity.id, @new_resource.name
    node.set[:cloud_monitoring][:alarms][@new_resource.name] = @current_resource.identity unless @current_resource.nil?
  end
end
