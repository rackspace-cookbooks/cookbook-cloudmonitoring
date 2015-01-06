include_recipe 'xml::ruby'

chef_gem "fog" do
  version ">= #{node['cloud_monitoring']['fog_version']}"
  action :install
end

include_recipe 'cloud_monitoring::agent_repo.rb'

# Get the agent id
if node['cloud_monitoring']['agent']['id'].nil?
  node.set['cloud_monitoring']['agent']['id'] = node['hostname']
end

# Try to retireve agent token from the data bag
begin
  databag_dir = node["cloud_monitoring"]["credentials"]["databag_name"]
  databag_filename = node["cloud_monitoring"]["credentials"]["databag_item"]

  values = Chef::EncryptedDataBagItem.load(databag_dir, databag_filename)

  node.set['cloud_monitoring']['agent']['token'] = values['agent_token'] || nil
rescue Exception => e
  Chef::Log.error 'Failed to load rackspace cloud data bag: ' + e.to_s
end

if node['cloud_monitoring']['agent']['token'].nil?
  get_agent_token
end

# If unable to retieve the agent token via API, create a new one
if node['cloud_monitoring']['agent']['token'].nil?
    create_token = cloud_monitoring_agent_token "#{node.hostname}" do
      rackspace_username  node['cloud_monitoring']['rackspace_username']
      rackspace_api_key   node['cloud_monitoring']['rackspace_api_key']
      action :create
    end

    retrieve_agent_token
end

package "rackspace-monitoring-agent" do
  if node['cloud_monitoring']['agent']['version'] == 'latest'
    action :upgrade
  else
    version node['cloud_monitoring']['agent']['version']
    action :install
  end

  notifies :restart, "service[rackspace-monitoring-agent]"
end

unless node['cloud_monitoring']['agent']['token'].nil?
  template "/etc/rackspace-monitoring-agent.cfg" do
    source "rackspace-monitoring-agent.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
      :monitoring_id => node['cloud_monitoring']['agent']['id'],
      :monitoring_token => node['cloud_monitoring']['agent']['token']
    )
    notifies :restart, "service[rackspace-monitoring-agent", :immediately
    notifies :restart, "service[rackspace-monitoring-agent", :delayed
  end
end

node['cloud_monitoring']['plugins'].each_pair do |source_cookbook, path|
  remote_directory "cloud_monitoring_plugins_#{source_cookbook}" do
    path node['cloud_monitoring']['plugin_path']
    cookbook source_cookbook
    source path
    files_mode 0755
    owner 'root'
    group 'root'
    mode 0755
    recursive true
    purge false
  end
end

service "rackspace-monitoring-agent" do
  # TODO: RHEL, CentOS, ... support
  supports value_for_platform(
    "ubuntu" => { "default" => [ :start, :stop, :restart, :status ] },
    "default" => { "default" => [ :start, :stop ] }
  )

  case node[:platform]
    when "ubuntu"
    if node[:platform_version].to_f >= 9.10
      provider Chef::Provider::Service::Upstart
    end
  end

  action [ :enable, :start ]
end
