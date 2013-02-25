define :rackspace_monitoring_check, :template => "" do

params['file'] ||= params['template']

  template "#{node['cloudmonitoring']['custom_check_dir']}/#{params['file']}" do
    source params['template']
    owner "root"
    group "root"
    mode 0755
    if params['cookbook']
      cookbook params['cookbook']
    end
    variables(
      :params => params
    )
  end
end
