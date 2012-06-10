include Rackspace::CloudMonitoring

action :create do
  entity = cm.entities.new(:label => new_resource.label, :ip_addresses => new_resource.ip_addresses,
                           :metadata => new_resource.metadata, :agent_id => new_resource.agent_id)
  if @current_resource.nil? then
    entity.save
    new_resource.updated_by_last_action(true)
    clear
  else
    # Compare attributes
    if !entity.compare? @current_resource then
      # It's different
      entity.id = @current_resource.id
      entity.save
      new_resource.updated_by_last_action(true)
      clear
    else
      new_resource.updated_by_last_action(false)
    end
  end
end


def load_current_resource
  @current_resource = nil
  if node[:cloud_monitoring][:entity_id] then
    @current_resource = cm.view[node[:cloud_monitoring][:entity_id]]
  end
  if @current_resource == nil then
    possible = view.select {|key, value| value.label === @new_resource.name}
    if !possible.empty? then
      @current_resource = possible.values.first
      node.set[:cloud_monitoring][:entity_id] = @current_resource.identity
    end
  end
end
