case node['platform']
when "ubuntu","debian"

  cookbook_file "#{Chef::Config[:file_cache_path]}/signing-key.asc" do
    source "signing-key.asc"
    mode 0755
    owner "root"
    group "root"
  end

  apt_repository "cloud-monitoring" do
    uri "http://stable.packages.cloudmonitoring.rackspace.com/ubuntu-10.04-x86_64"
    distribution "cloudmonitoring"
    components ["main"]
    key "signing-key.asc"
    action :add
  end

end
# TODO: Enable once we set it up
# apt_repository "cloud-monitoring-release" do
#  uri "http://stable.packages.cloudmonitoring.rackspace.com/linux-x86_64-ubuntu-10.04"
#  distribution "cloudmonitoring"
#  components ["main"]
#  key "signing-key.asc"
#  action :add
#end

begin
  values = Chef::EncryptedDataBagItem.load('rackspace', 'cloud')

  node.set['cloud_monitoring']['agent']['token'] = values['agent_token'] || nil
rescue Exception => e
  Chef::Log.error 'Failed to load rackspace cloud data bag: ' + e.to_s
end

if not node['cloud_monitoring']['agent']['token']

  if not node['cloud_monitoring']['rackspace_username'] or not node['cloud_monitoring']['rackspace_api_key']
    raise RuntimeError, "agent_token variable or rackspace credentials must be set on the node."

  #This runs at compile time as it needs to finish before the template for the config file fires off.
  else
    e = cloud_monitoring_agent_token "#{node.hostname}" do
      rackspace_username  node['cloud_monitoring']['rackspace_username']
      rackspace_api_key   node['cloud_monitoring']['rackspace_api_key']
      action :nothing
    end
    e.run_action(:create)

  end

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

template "/etc/rackspace-monitoring-agent.cfg" do
  source "rackspace-monitoring-agent.erb"
  owner "root"
  group "root"
  mode 0600
  variables(
    :monitoring_id => node['cloud_monitoring']['agent']['id'],
    :monitoring_token => node['cloud_monitoring']['agent']['token']
  )
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
