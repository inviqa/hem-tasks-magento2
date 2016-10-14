#!/usr/bin/env ruby
# ^ Syntax hint

desc 'Setup cache, session, varnish settings and magento mode variables'
task :configure do
  Hem.ui.title('Updating Magento2 configuration')
  configuration_file = File.join(Hem.project_config.vm.project_mount_path, 'configure-magento-config.php')
  run_command "php #{configuration_file}", realtime: true, indent: 2

  [
    File.join(Hem.project_config.vm.project_mount_path, 'var', 'cache'),
    File.join(Hem.project_config.vm.project_mount_path, 'var', 'page_cache')
  ].each do |dir|
    run "sudo rm -rf '#{dir}/*'", realtime: true, indent: 2
  end

  Hem.ui.success('Magento2 configuration update finished')
end
