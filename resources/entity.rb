# encoding: UTF-8
actions :create, :delete
default_action :create

attribute :label, kind_of: String, name_attribute: true
attribute :api_label, kind_of: String
attribute :metadata, kind_of: Hash
attribute :ip_addresses, kind_of: Hash
attribute :agent_id, kind_of: String

attribute :search_method, kind_of: String
attribute :search_ip, kind_of: String
attribute :search_id, kind_of: String

attribute :rackspace_api_key, kind_of: String
attribute :rackspace_username, kind_of: String
attribute :rackspace_auth_url, kind_of: String
