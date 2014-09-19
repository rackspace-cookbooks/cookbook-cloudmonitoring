name             "cloud_monitoring"
maintainer       "Rackspace"
maintainer_email "daniel.dispaltro@rackspace.com"
license          "Apache 2.0"
description      "Installs/Configures Rackspace Cloud Monitoring"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version          "1.0.5"

depends "apt", ">= 1.4.2"
depends "python"
depends "yum"
depends "xml"

#chef_gem cookbook/library required for chef versions <= 10.12.0
recommends "chef_gem"
