#!/usr/bin/env ruby
# ^ Syntax hint

desc "Index related functionality"
namespace :index do
  desc "Reindex indexers"
  task :refresh do
    Hem.ui.title "Reindex indexers"
    run_command "bin/magento indexer:reindex", :realtime => true, :indent => 2
    Hem.ui.success("Reindexing complete")
  end
end
