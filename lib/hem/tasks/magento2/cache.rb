#!/usr/bin/env ruby
# ^ Syntax hint

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
