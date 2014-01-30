# encoding: UTF-8
actions :create, :update, :delete
default_action :update

attribute :label, kind_of:  String, name_attribute:  true
attribute :token, kind_of:  String

attribute :rackspace_api_key, kind_of:  String
attribute :rackspace_username, kind_of:  String
attribute :rackspace_auth_url, kind_of:  String
