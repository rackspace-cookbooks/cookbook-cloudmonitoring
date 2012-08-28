
cookbook_file "#{Chef::Config[:file_cache_path]}/signing-key.asc" do
  source "signing-key.asc"
  mode 0755
  owner "root"
  group "root"
end

# Repo doesn't currently update atomically, leading to random failures
# We're going to stop using nightly builds until this is fixed.
apt_repository "cloud-monitoring" do
  uri "http://packages-master.cloudmonitoring.rackspace.com/ubuntu-10.04"
  distribution "cloudmonitoring"
  components ["main"]
  key "signing-key.asc"
  action :remove
end

apt_repository "cloud-monitoring-release" do
  uri "http://packages.cloudmonitoring.rackspace.com/ubuntu-10.04"
  distribution "cloudmonitoring"
  components ["main"]
  key "signing-key.asc"
  action :add
end

if Chef::DataBag.list.keys.include?('rackspace') && data_bag('rackspace').include?('cloud')
  values = Chef::EncryptedDataBagItem.load('rackspace', 'cloud')

  node['cloud_monitoring']['agent']['token'] = values['agent_token'] || nil
end

if not node['cloud_monitoring']['agent']['token']
  raise RuntimeError, "agent_token variable must be set on the node."
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
