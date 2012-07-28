maintainer       "Rackspace"
maintainer_email "daniel.dispaltro@rackspace.com"
license          "Apache 2.0"
description      "Installs/Configures Rackspace Cloud Monitoring"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.3"

depends "python"
# TODO: Add correct apt / yum repo, etc. once available
depends "apt-ck"
