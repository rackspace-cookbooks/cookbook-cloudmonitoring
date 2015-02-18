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
  releaseVersion = node['platform_version'].split('.').first

  # We need to figure out which signing key to use, cent5 and rhel5 have their own.
  if (node['platform'] == 'centos') && (releaseVersion == '5')
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/centos-5.asc'
  elsif (node['platform'] == 'redhat') && (releaseVersion == '5')
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/redhat-5.asc'
  elsif (node['platform'] == 'redhat') && (releaseVersion == '6')
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/redhat-6.asc'
  else
    signingKey = 'https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc'
  end

  yum_repository 'cloud-monitoring' do
    description 'Rackspace Monitoring'
    url "http://stable.packages.cloudmonitoring.rackspace.com/#{node['platform']}-#{releaseVersion}-#{node['kernel']['machine']}"
    gpgkey signingKey
    action :add
  end
end
