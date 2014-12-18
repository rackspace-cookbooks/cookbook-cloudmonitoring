raise "CloudMonitoring agent token not found!" unless node['cloud_monitoring']['agent']['token']

case node['platform']
when "ubuntu", "debian"

  apt_repository "cloud-monitoring" do

    if node['platform'] == 'ubuntu'
      uri "http://stable.packages.cloudmonitoring.rackspace.com/ubuntu-#{node['platform_version']}-#{node['kernel']['machine']}"
    elsif node['platform'] =='debian'
      uri "http://stable.packages.cloudmonitoring.rackspace.com/debian-#{node['lsb']['codename']}-#{node['kernel']['machine']}"
    end

    distribution "cloudmonitoring"
    components ["main"]
    key "https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc" 
    action :add
  end


when "redhat","centos","fedora", "amazon","scientific"

  #Grab the major release for cent and rhel servers as this is what the repos use.
  releaseVersion = node['platform_version'].split('.').first

  #We need to figure out which signing key to use, cent5 and rhel5 have their own.
  if (node['platform'] == 'centos') && (releaseVersion == '5')
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/centos-5.asc' 
  elsif (node['platform'] == 'redhat') && (releaseVersion == '5')
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/redhat-5.asc'
  elsif (node['platform'] == 'redhat') && (releaseVersion == '6')
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/redhat-6.asc'
  else
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc'
  end

  yum_repository "cloud-monitoring" do
    description "Rackspace Monitoring"
    url "http://stable.packages.cloudmonitoring.rackspace.com/#{node['platform']}-#{releaseVersion}-#{node['kernel']['machine']}"
    gpgkey signingKey
    action :add
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
  subscribes :restart, resources(:template => '/etc/rackspace-monitoring-agent.cfg'), :delayed
end
