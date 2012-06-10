actions :create, :update, :disable, :delete

attribute :label, :kind_of => String, :name_attribute => true
attribute :metadata, :kind_of => Hash
attribute :ip_addresses, :kind_of => Hash
attribute :agent_id, :kind_of => String
attribute :rackspace_api_key, :kind_of => String
attribute :rackspace_username, :kind_of => String
