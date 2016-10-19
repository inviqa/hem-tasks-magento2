#!/usr/bin/env ruby
# ^ Syntax hint

desc 'Magento2 installation related tasks'
namespace :install do
  desc 'Create the vendor and bin directories'
  task :create_vendor_dir do
    Hem.ui.title 'Creating vendor directory'
    FileUtils.mkdir_p(File.join(Hem.project_path, 'bin'))
    FileUtils.mkdir_p(File.join(Hem.project_path, 'vendor'))
    Hem.ui.success('Vendor directory created')
  end

  desc "Move the composer file to the project's root folder"
  task :move_composer_json_file do
    unless File.exist? File.join(Hem.project_path, 'composer.json')
      Hem.ui.title 'Setup composer file'
      target_file = File.join(Hem.project_path, 'composer.json')
      FileUtils.cp Hem.project_config.composer_file, target_file
      Hem.ui.success('Composer file copied to the correct place')
    end
  end

  desc 'Installs Magento based on the install shell script'
  task :install_magento do
    magento_config = File.join(Hem.project_path, 'app', 'etc', 'env.php')
    magento_installer = File.join(Hem.project_config.vm.project_mount_path, 'install-magento2.sh')

    unless File.exist? magento_config
      Rake::Task['magento2:install:set_permissions'].invoke

      Hem.ui.title 'Installing Magento2'
      run_command "sh #{magento_installer}", realtime: true, indent: 2
      Hem.ui.success('Magento2 install finished')

      Rake::Task['magento2:configure'].invoke
      Rake::Task['magento2:sample_data:add'].invoke(from_install: true)
    end

    Rake::Task['magento2:install:set_permissions'].execute
    Rake::Task['magento2:install:optimise_autoloader'].invoke

    Rake::Task['magento2:setup_script:run'].invoke
    Rake::Task['magento2:index:refresh'].invoke
    Rake::Task['magento2:cache:clean'].invoke
    Rake::Task['magento2:development:asset_symlinks'].invoke
    Rake::Task['magento2:development:compile_less'].invoke
  end

  desc 'Optimise the composer autoloader for a speed boost'
  task :optimise_autoloader do
    Hem.ui.title 'Optimising composer autoloader'
    run_command 'bin/composer.phar dump-autoload --optimize', realtime: true, indent: 2
    Hem.ui.success('Composer optimisation finished')
  end

  desc 'Sets up magento permissions'
  task :set_permissions do
    Hem.ui.title 'Setup permissions'

    magento_binfile = File.join(Hem.project_config.vm.project_mount_path, 'bin', 'magento')
    chmod_dirs = [
      File.join(Hem.project_config.vm.project_mount_path, 'pub', 'media'),
      File.join(Hem.project_config.vm.project_mount_path, 'pub', 'static')
    ]
    var_directory = File.join(Hem.project_config.vm.project_mount_path, 'var')

    var_is_bind_mount = run 'grep "/vagrant/var ext4" /proc/mounts || true', capture: true
    chmod_dirs << var_directory if var_is_bind_mount == ''

    Hem.ui.title "Setup permissions - #{magento_binfile}"
    run_command "sudo chmod +x #{magento_binfile}", realtime: true, indent: 2

    unless var_is_bind_mount == ''
      Hem.ui.title "Setup permissions - #{var_directory}"
      run_command "sudo setfacl -R -m 'u:apache:rwX' -m 'u:vagrant:rwX' '#{var_directory}'", realtime: true, indent: 2
      run_command "sudo setfacl -dR -m 'u:apache:rwX' -m 'u:vagrant:rwX' '#{var_directory}'", realtime: true, indent: 2
    end

    chmod_dirs.each do |dir|
      Hem.ui.title "Setup permissions - #{dir}"
      run_command "if [ -e '#{dir}' ]; then sudo find '#{dir}' -type d -exec chmod a+rwx {} + ; fi",
                  realtime: true,
                  indent: 2
      run_command "if [ -e '#{dir}' ]; then sudo find '#{dir}' -type f -exec chmod a+rw {} + ; fi",
                  realtime: true,
                  indent: 2
    end

    Hem.ui.success('Permissions setup finished')
  end
end
