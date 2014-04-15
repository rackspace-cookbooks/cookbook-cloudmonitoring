name             'rackspace_cloudmonitoring'
maintainer       'Rackspace, US, Inc.'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license          'Apache 2.0'
description      'Installs/Configures Rackspace Cloud Monitoring'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version          '3.1.0'

depends 'rackspace_apt', '~> 3.0'
depends 'rackspace_yum', '~> 4.0'

# TODO: Update these to rackspace-* cookbooks
# build essential is done, but XML is not.  XML flagged in rebuild tracker.
depends 'xml', '~> 1.1'

# Conflict with the earlier version we forked from as they won't play nice with each other
conflicts 'cloud_monitoring'
