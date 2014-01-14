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
  else
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc'
  end

  yum_key "Rackspace-Monitoring" do
    url signingKey
    action :add
  end

  yum_repository "cloud-monitoring" do
    description "Rackspace Monitoring"
    url "http://stable.packages.cloudmonitoring.rackspace.com/#{node['platform']}-#{releaseVersion}-#{node['kernel']['machine']}"
    action :add
  end

end

begin
  databag_dir = node[:rackspace_cloudmonitoring]["credentials"]["databag_name"]
  databag_filename = node[:rackspace_cloudmonitoring]["credentials"]["databag_item"]

  values = Chef::EncryptedDataBagItem.load(databag_dir, databag_filename)

  node.set[:rackspace_cloudmonitoring]['agent']['token'] = values['agent_token'] || nil
rescue Exception => e
  Chef::Log.error 'Failed to load rackspace cloud data bag: ' + e.to_s
end


#The first time this recipe runs on the node it is unable to pull token from the node attributes, unless they were put there by hand or in the data bag.
#There's also no simple way to get data directly back from a provider.
#So we're creating the auth_token with the LWRP, then using fog to pull it back out of the API. If you can find a better way to handle this, please rewrite it.
if node[:rackspace_cloudmonitoring]['agent']['token'].nil?

  if node[:rackspace_cloudmonitoring]['rackspace_username'] == "your_rackspace_username" or  node[:rackspace_cloudmonitoring]['rackspace_api_key'] == "your_rackspace_api_key"
    raise RuntimeError, "No Rackspace credentials found"

  #Create the token within the api, I'm using run_action to make sure everything happens in the proper order.
  else
    create_token = rackspace_cloudmonitoring_agent_token "#{node.hostname}" do
      rackspace_username  node[:rackspace_cloudmonitoring]['rackspace_username']
      rackspace_api_key   node[:rackspace_cloudmonitoring]['rackspace_api_key']
      action :nothing
    end

    create_token.run_action(:create)

    #Pull just the token itself into a variable named token
    label = "#{node.hostname}"
    monitoring = Fog::Rackspace::Monitoring.new(
      :rackspace_api_key => node[:rackspace_cloudmonitoring]['rackspace_api_key'],
      :rackspace_username => node[:rackspace_cloudmonitoring]['rackspace_username']
    )
    tokens = Hash[monitoring.agent_tokens.all.map  {|x| [x.label, x]}]
    possible = tokens.select {|key, value| value.label === label}
    possible = Hash[*possible.flatten(1)]

    if !possible.empty? then
      possible.values.first
    else
      nil
    end

    token = possible[label].token

    if Chef::Config[:solo]
      Chef::Log.warn("Under chef-solo, you must persist the agent token to " +
                     "node[:rackspace_cloudmonitoring]['agent']['token'] or you will " +
                     "regenerate the token every time. TOKEN: #{token}")
    end

    #Fire off a template run using the token pulled out of fog. This should only ever run on a new node, or if your node attributes get lost.
    config_template = template "/etc/rackspace-monitoring-agent.cfg" do
      source "rackspace-monitoring-agent.erb"
      owner "root"
      group "root"
      mode 0600
      variables(
        :monitoring_id => "#{node.hostname}",
        :monitoring_token =>  token
      )
      action :nothing
    end

    config_template.run_action(:create)

  end

end




package "rackspace-monitoring-agent" do
  if node[:rackspace_cloudmonitoring]['agent']['version'] == 'latest'
    action :upgrade
  else
    version node[:rackspace_cloudmonitoring]['agent']['version']
    action :install
  end

  notifies :restart, "service[rackspace-monitoring-agent]"
end

unless node[:rackspace_cloudmonitoring]['agent']['token'].nil?
  template "/etc/rackspace-monitoring-agent.cfg" do
    source "rackspace-monitoring-agent.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
      :monitoring_id => node[:rackspace_cloudmonitoring]['agent']['id'],
      :monitoring_token => node[:rackspace_cloudmonitoring]['agent']['token']
    )
  end
end

node[:rackspace_cloudmonitoring]['plugins'].each_pair do |source_cookbook, path|
  remote_directory "rackspace_cloudmonitoring_plugins_#{source_cookbook}" do
    path node[:rackspace_cloudmonitoring]['plugin_path']
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
