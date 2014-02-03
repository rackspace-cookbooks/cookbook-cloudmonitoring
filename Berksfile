metadata

cookbook "rackspace_yum",  "~> 4.0", git: "https://github.com/rackspace-cookbooks/rackspace_yum"
cookbook "rackspace_apt", "~> 3.0", git: "https://github.com/rackspace-cookbooks/rackspace_apt"

# Dependency of dependency cookbooks
cookbook "xml", "~> 1.1", git: "https://github.com/rackspace-cookbooks/xml"
# This is a dep of XML, which has not been cut over yet.
# As such we can't use rackspace_build_essential due to the namespace change yet.
cookbook "build-essential", "~> 1.4", git: "https://github.com/rackspace-cookbooks/rackspace_build_essential", tag: "pre-rebuild"
