#!/usr/bin/env ruby
# ^ Syntax hint

before 'vm:up', 'magento2:install:create_vendor_dir'
before 'vm:up', 'magento2:install:move_composer_json_file'
after 'vm:up', 'magento2:initialize-vm'

namespace :magento2 do
  require_relative 'magento2/install'
  require_relative 'magento2/configure'
  require_relative 'magento2/sample_data'
  require_relative 'magento2/setup_script'
  require_relative 'magento2/index'
  require_relative 'magento2/cache'
  require_relative 'magento2/development'

  desc 'Initializes Magento2 specifics on the virtual machine after a fresh build'
  task 'initialize-vm': [
    'magento2:install:install_magento'
  ]
end
