case node['platform']
when 'ubuntu', 'debian'

  apt_repository 'cloud-monitoring' do
    if node['platform'] == 'ubuntu'
      uri "http://stable.packages.cloudmonitoring.rackspace.com/ubuntu-#{node['platform_version']}-#{node['kernel']['machine']}"
    elsif node['platform'] == 'debian'
      uri "http://stable.packages.cloudmonitoring.rackspace.com/debian-#{node['lsb']['codename']}-#{node['kernel']['machine']}"
    end

    distribution 'cloudmonitoring'
    components ['main']
    key 'https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc'
    action :add
  end

when 'redhat', 'centos', 'fedora', 'amazon', 'scientific'

  # Grab the major release for cent and rhel servers as this is what the repos use.
  release_version = node['platform_version'].split('.').first

  # We need to figure out which signing key to use, cent5 and rhel5 have their own.
  if (node['platform'] == 'centos') && (release_version == '5')
    signing_key = 'https://monitoring.api.rackspacecloud.com/pki/agent/centos-5.asc'
  elsif (node['platform'] == 'redhat') && (release_version == '5')
    signing_key = 'https://monitoring.api.rackspacecloud.com/pki/agent/redhat-5.asc'
  elsif (node['platform'] == 'redhat') && (release_version == '6')
    signing_key = 'https://monitoring.api.rackspacecloud.com/pki/agent/redhat-6.asc'
  else
    signing_key = 'https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc'
  end

  yum_repository 'cloud-monitoring' do
    description 'Rackspace Monitoring'
    url "http://stable.packages.cloudmonitoring.rackspace.com/#{node['platform']}-#{release_version}-#{node['kernel']['machine']}"
    gpgkey signing_key
    action :add
  end
end
