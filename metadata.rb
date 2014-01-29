name             'rackspace_cloudmonitoring'
maintainer       'Rackspace, US, Inc.'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license          'Apache 2.0'
description      'Installs/Configures Rackspace Cloud Monitoring'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version          '2.0.7'

depends 'rackspace_apt', '~> 3.0'
depends 'rackspace_yum', '~> 4.0'
# TODO: Update these to rackspace-* cookbooks
depends 'xml', '~> 1.2'
# Dep of xml
depends 'build-essential'

# Conflict with the earlier version we forked from, we will conflict
conflicts 'cloud_monitoring'
