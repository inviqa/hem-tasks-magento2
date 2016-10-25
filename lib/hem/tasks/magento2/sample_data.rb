#!/usr/bin/env ruby
# ^ Syntax hint

desc 'Sample data related functionality'
namespace :sample_data do
  def execute_if_defined(task_name)
    Rake::Task[task_name].execute if Rake::Task.task_defined?(task_name)
  end

  desc 'Adds Sample data to Magento 2'
  argument :from_install, optional: true, default: false
  task :add do |_task_name, task_args|
    sample_data_answer = nil
    sample_data_answer = Hem.project_config[:sample_data] unless Hem.project_config[:sample_data].nil?
    sample_data_answers = ['yes', 'no']
    unless sample_data_answers.include?(Hem.project_config[:sample_data])
      sample_data_answer = Hem.ui.ask_choice("Sample data", sample_data_answers, :default => 'yes')
      Hem.project_config[:sample_data] = sample_data_answer
      Hem::Config::File.save(Hem.project_config_file, Hem.project_config)
    end

    # Return early if we aren't meant to install sample data
    next unless sample_data_answer == 'yes'

    Hem.ui.title 'Installing sample data'

    args = ['php -d memory_limit=-1 bin/magento sampledata:deploy', realtime: true, indent: 2]
    complete = false

    unless maybe(Hem.project_config.tasks.deps.composer.disable_host_run)
      check = Hem::Lib::HostCheck.check(filter: /php_present/)

      if check[:php_present] == :ok
        begin
          shell(*args)

          complete = true
        rescue Hem::ExternalCommandError
          Hem.ui.warning 'Installing sample data locally failed!'
        end
      end
    end

    run(*args) unless complete

    execute_if_defined('deps:sync:vendor_directory')

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
