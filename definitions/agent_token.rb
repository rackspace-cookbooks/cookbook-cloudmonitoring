define :retrieve_agent_token do
  if node['cloud_monitoring']['rackspace_username'] == "your_rackspace_username" or  node['cloud_monitoring']['rackspace_api_key'] == "your_rackspace_api_key"
    raise RuntimeError, "No Rackspace credentials found"

  #Create the token within the api, I'm using run_action to make sure everything happens in the proper order.
  else
    #Pull just the token itself into a variable named token
    label = node['cloud_monitoring']['agent']['id']

    require 'fog'

    monitoring = Fog::Rackspace::Monitoring.new(
      :rackspace_api_key => node['cloud_monitoring']['rackspace_api_key'],
      :rackspace_username => node['cloud_monitoring']['rackspace_username']
    )
    tokens = Hash[monitoring.agent_tokens.all.map  {|x| [x.label, x]}]
    possible = tokens.select {|key, value| value.label === label}
    possible = Hash[*possible.flatten(1)]

    if !possible.empty? then
      possible.values.first
    else
      nil
    end

    node.set['cloud_monitoring']['agent']['token'] = possible[label].token
  end
end
