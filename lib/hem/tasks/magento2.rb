#!/usr/bin/env ruby
# ^ Syntax hint

task "vm:up" => ["magento2:initialize-vm"]

namespace :magento2 do
  desc "Initializes Magento2 specifics on the virtual machine after a fresh build"
  task :'initialize-vm' => [
    'magento2:install:install_magento',
  ]

  desc "Magento2 installation related tasks"
  namespace :install do

    desc "Move the composer file to the project's root folder"
    task :move_composer_json_file do

      unless File.exists? File.join(Hem.project_path, 'composer.json')
        Hem.ui.title "Setup composer file"
        FileUtils.cp Hem.project_config.composer_file, File.join(Hem.project_path, 'composer.json')
        Hem.ui.success("Composer file copied to the correct place")
      end

      unless File.directory? File.join(Hem.project_path, 'vendor')
        Hem.ui.title "Running composer install"
        run_command "[ -f /etc/php.d/xdebug.ini.disabled ] || sudo mv /etc/php.d/xdebug.ini /etc/php.d/xdebug.ini.disabled", :realtime => true, :indent => 2
        run_command "composer install --ansi --prefer-dist", :realtime => true, :indent => 2
        run_command "[ -f /etc/php.d/xdebug.ini ] || sudo mv /etc/php.d/xdebug.ini.disabled /etc/php.d/xdebug.ini", :realtime => true, :indent => 2
        Hem.ui.title "Finished composer install"
      end

    end

    desc "Installs Magento based on the install shell script"
    task :install_magento do
      magento_config = File.join(Hem.project_path, "app", "etc", "env.php");
      magento_installer = File.join(Hem.project_config.vm.project_mount_path, "install-magento2.sh");

      unless File.exists? magento_config

        Rake::Task["magento2:install:move_composer_json_file"].invoke

        Hem.ui.title "Installing Magento2"

        run_command "sh #{magento_installer}", :realtime => true, :indent => 2

        Hem.ui.success("Magento2 install finished")

        Hem.ui.title "Setup permissions"

        magento_binfile = File.join(Hem.project_config.vm.project_mount_path, "bin", "magento");
        magento_var_directory = File.join(Hem.project_config.vm.project_mount_path, "var");
        magento_media_directory = File.join(Hem.project_config.vm.project_mount_path, "pub", "media");
        magento_static_directory = File.join(Hem.project_config.vm.project_mount_path, "pub", "static");

        Hem.ui.title "Setup permissions - #{magento_binfile}"
        Hem.ui.title "Setup permissions - #{magento_var_directory}"
        Hem.ui.title "Setup permissions - #{magento_media_directory}"
        Hem.ui.title "Setup permissions - #{magento_static_directory}"

        run_command "sudo chmod +x #{magento_binfile}", :realtime => true, :indent => 2
        run_command "sudo chmod -R 777 #{magento_var_directory}", :realtime => true, :indent => 2
        run_command "sudo chmod -R 777 #{magento_media_directory}", :realtime => true, :indent => 2
        run_command "sudo chmod -R 777 #{magento_static_directory}", :realtime => true, :indent => 2

        Hem.ui.success("Permissions setup finished")

        Rake::Task["magento2:install:configure"].invoke
        Rake::Task["magento2:install:add_sample_data"].invoke
        Rake::Task["magento2:setup:upgrade"].invoke
        Rake::Task["magento2:indexer:reindex"].invoke
        Rake::Task["magento2:cache:clean"].invoke
      end
    end

    desc "Setup cache, session, varnish settings and magento mode variables"
    task :configure do
      Hem.ui.title("Updating Magento2 configuration")
      configuration_file = File.join(Hem.project_config.vm.project_mount_path, "configure-magento-config.php");
      run_command "php #{configuration_file}", :realtime => true, :indent => 2

      [File.join(Hem.project_path, "var", "cache"), File.join(Hem.project_path, "var", "page_cache")].each do |dir|
        FileUtils.rm_rf("#{dir}/.", secure: true)
      end

      Hem.ui.success("Magento2 configuration update finished")
    end

    desc "Adds Sample data to Magento 2"
    task :add_sample_data do
      sample_data_answer = 'no'
      sample_data_answers = ['yes', 'no']
      if Hem.project_config[:sample_data].nil? || !sample_data_answers.include?(Hem.project_config[:sample_data])
        sample_data_answer = Hem.ui.ask_choice("Sample data", sample_data_answers, :default => 'yes')
        Hem.project_config[:sample_data] = sample_data_answer
        Hem::Config::File.save(Hem.project_config_file, Hem.project_config)
      end

      if sample_data_answer == "yes"
        Hem.ui.title "Installing sample data"
        ansi = Hem.ui.supports_color? ? '--ansi' : ''
        complete = false


        run_command "[ -f /etc/php.d/xdebug.ini ] && sudo mv /etc/php.d/xdebug.ini /etc/php.d/xdebug.ini.disabled", :realtime => true, :indent => 2
        run_command "php -d memory_limit=-1 bin/magento sampledata:deploy", :realtime => true, :indent => 2
        run_command "[ -f /etc/php.d/xdebug.ini.disabled ] && sudo mv /etc/php.d/xdebug.ini.disabled /etc/php.d/xdebug.ini", :realtime => true, :indent => 2
        magento_var_directory = File.join(Hem.project_config.vm.project_mount_path, "var");
        run_command "sudo rm -rf #{magento_var_directory}/*", :realtime => true, :indent => 2
      end
    end
  end

  desc "Setup script related functionality"
  namespace :setup do
    desc "Run setup scripts"
    task :upgrade do
      Hem.ui.title "Running setup scripts"
      run_command "bin/magento setup:upgrade", :realtime => true, :indent => 2
      Hem.ui.success("Setup scripts finished")
    end
  end

  desc "Index related functionality"
  namespace :indexer do
    desc "Reindex indexers"
    task :reindex do
      Hem.ui.title "Reindex indexers"
      run_command "bin/magento indexer:reindex", :realtime => true, :indent => 2
      Hem.ui.success("Reindexing complete")
    end
  end

  desc "Cache related functionality"
  namespace :cache do
    desc "Clean cache"
    task :clean do
      Hem.ui.title "Cleaning cache"
      run_command "bin/magento cache:clean", :realtime => true, :indent => 2
      Hem.ui.success("Cache cleaned")
    end

    desc "Flush cache"
    task :flush do
      Hem.ui.title "Cleaning cache"
      run_command "bin/magento cache:flush", :realtime => true, :indent => 2
      Hem.ui.success("Cache flushed")
    end
  end
end
