#!/usr/bin/env ruby
# ^ Syntax hint

desc "Setup script related functionality"
namespace :setup_script do
  desc "Run setup scripts"
  task :run do
    Hem.ui.title "Running setup scripts"
    run_command "bin/magento setup:upgrade", :realtime => true, :indent => 2
    Hem.ui.success("Setup scripts finished")
  end
end
