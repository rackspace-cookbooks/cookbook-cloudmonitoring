name             "rackspace_cloudmonitoring"
maintainer       "Rackspace, US, Inc."
maintainer_email "rackspace-cookbooks@rackspace.com"
license          "Apache 2.0"
description      "Installs/Configures Rackspace Cloud Monitoring"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version          "2.0.0"

# TODO: Update these to meet our dep spec
depends "apt", ">= 1.4.2"
depends "python"
depends "yum", "~> 2.0"
depends "xml"

#chef_gem cookbook/library required for chef versions <= 10.12.0
recommends "chef_gem"
