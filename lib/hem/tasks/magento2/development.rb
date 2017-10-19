#!/usr/bin/env ruby
# ^ Syntax hint

desc 'Development related functionality'
namespace :development do
  desc 'Quickly create the asset symlinks for development mode'
  task :asset_symlinks do
    Hem.ui.title 'Creating asset symlinks to pub/static/'
    run_command 'sudo php tools/magento2/create_development_symlinks.php', realtime: true, indent: 2
    Hem.ui.success('Asset symlinks finished')
  end

  desc 'Compile the less files'
  task :compile_less do
    Rake::Task['magento2:development:compile_less_frontend'].invoke
    Rake::Task['magento2:development:compile_less_backend'].invoke
  end

  desc 'Compile the less files for the frontend themes'
  task :compile_less_frontend do
    has_javascript_option = run 'bin/magento setup:static-content:deploy --help | grep -- --no-javascript || true',
                                capture: true

    next if has_javascript_option == ''

    has_force_option = run 'bin/magento setup:static-content:deploy --help | grep -- --force || true',
                           capture: true

    Hem.ui.title 'Compiling Less files for the en_GB frontend'
    command = 'bin/magento setup:static-content:deploy --no-javascript '\
              '--no-images --no-html --no-misc --no-fonts --no-css '\
              '--language en_GB --area frontend '\
              '--theme Magento/luma --theme Magento/blank'
    command += ' --force' if has_force_option
    run_command command, realtime: true, indent: 2
    Hem.ui.success('Compile finished')
  end

  desc 'Compile the less files for the admin/backend themes'
  task :compile_less_backend do
    has_javascript_option = run 'bin/magento setup:static-content:deploy --help | grep -- --no-javascript || true',
                                capture: true

    next if has_javascript_option == ''

    has_force_option = run 'bin/magento setup:static-content:deploy --help | grep -- --force || true',
                           capture: true

    Hem.ui.title 'Compiling Less files for the en_GB and en_US backend'
    command = 'bin/magento setup:static-content:deploy --no-javascript '\
              '--no-images --no-html --no-misc --no-fonts --no-css '\
              '--language en_GB --language en_US --area adminhtml'
    command += ' --force' if has_force_option
    run_command command, realtime: true, indent: 2
    Hem.ui.success('Compile finished')
  end

  desc 'Compile the Dependency Injection container'
  task :compile_di do
    Hem.ui.title 'Compiling the Dependency Injection container'
    run_command 'bin/magento setup:di:compile', realtime: true, indent: 2
    Hem.ui.success('Compile finished')
  end
end
