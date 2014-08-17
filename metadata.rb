name             'rackspace_cloudmonitoring'
maintainer       'Rackspace, US, Inc.'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license          'Apache 2.0'
description      'Installs/Configures Rackspace Cloud Monitoring'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version          '4.0.1'

depends 'apt', '~> 2.4'
depends 'yum', '~> 3.2'
depends 'build-essential', '~> 2.0'
depends 'xml', '~> 1.2'

# Conflict with the earlier version we forked from as they won't play nice with each other
conflicts 'cloud_monitoring'
