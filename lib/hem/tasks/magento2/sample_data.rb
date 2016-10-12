#!/usr/bin/env ruby
# ^ Syntax hint

desc 'Sample data related functionality'
namespace :sample_data do
  desc 'Adds Sample data to Magento 2'
  argument :from_install, optional: true, default: false
  task :add do |_task_name, task_args|
    sample_data_answer = 'no'
    sample_data_answers = %w(yes no)
    if Hem.project_config[:sample_data].nil? || !sample_data_answers.include?(Hem.project_config[:sample_data])
      sample_data_answer = Hem.ui.ask_choice('Sample data', sample_data_answers, default: 'yes')
      Hem.project_config[:sample_data] = sample_data_answer
      Hem::Config::File.save(Hem.project_config_file, Hem.project_config)
    end

    if sample_data_answer == 'yes'
      Hem.ui.title 'Installing sample data'
      ansi = Hem.ui.supports_color? ? '--ansi' : ''
      complete = false

      args = ['php -d memory_limit=-1 bin/magento sampledata:deploy', realtime: true, indent: 2]
      complete = false

      unless maybe(Hem.project_config.tasks.deps.composer.disable_host_run)
        check = Hem::Lib::HostCheck.check(filter: /php_present/)

        if check[:php_present] == :ok
          begin
            shell *args

            Rake::Task['vm:rsync_mount_sync'].execute if Rake::Task.task_defined?('vm:rsync_mount_sync')

            complete = true
          rescue Hem::ExternalCommandError
            Hem.ui.warning 'Installing sample data locally failed!'
          end
        end
      end

      unless complete
        run *args

        Rake::Task['deps:sync:composer_files_from_guest'].execute if Rake::Task.task_defined?('deps:sync:composer_files_from_guest')
        Rake::Task['deps:sync:vendor_directory_from_guest'].execute if Rake::Task.task_defined?('deps:sync:vendor_directory_from_guest')
      end

      magento_var_directory = File.join(Hem.project_config.vm.project_mount_path, 'var')
      run_command "sudo rm -rf #{magento_var_directory}/*", realtime: true, indent: 2

      Rake::Task['magento2:install:set_permissions'].invoke
      Rake::Task['magento2:setup_script:run'].invoke

      unless task_args[:from_install]
        Rake::Task['magento2:development:asset_symlinks'].invoke
        Rake::Task['magento2:development:compile_less'].invoke
      end
    end
  end
end
