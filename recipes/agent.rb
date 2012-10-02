cookbook_file "#{Chef::Config[:file_cache_path]}/signing-key.asc" do
  source "signing-key.asc"
  mode 0755
  owner "root"
  group "root"
end

apt_repository "cloud-monitoring" do
  uri "http://unstable.packages.cloudmonitoring.rackspace.com/linux-x86_64-ubuntu-10.04"
  distribution "cloudmonitoring"
  components ["main"]
  key "signing-key.asc"
  action :add
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

  node['cloud_monitoring']['agent']['token'] = values['agent_token'] || nil
rescue Exception => e
  Chef::Log.error 'Failed to load rackspace cloud data bag: ' + e.to_s
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
