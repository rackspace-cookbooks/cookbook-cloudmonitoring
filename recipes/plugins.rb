
node['cloud_monitoring']['plugins'].each_pair do |source_cookbook, path|
  remote_directory node['cloud_monitoring']['plugin_path'] do
    cookbook source_cookbook
    source path
    files_mode 0755
    owner 'root'
    group 'root'
    mode 0755
    recursive true
    purge false
  end
end
