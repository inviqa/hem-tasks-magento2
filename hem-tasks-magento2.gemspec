# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hem/tasks/magento2/version'

Gem::Specification.new do |spec|
  spec.name          = "hem-tasks-magento2"
  spec.version       = Hem::Tasks::Magento2::VERSION
  spec.authors       = ["Norbert Nagy", "Kieren Evans"]
  spec.email         = ["nnagy@inviqa.com", "kevans+hem_tasks@inviqa.com"]

  spec.summary       = %q{Magento 2 tasks for Hem}
  spec.description   = %q{Magento 2 tasks for Hem}
  spec.homepage      = ""
  spec.licenses = ["MIT"]

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rubocop', '~> 0.43.0'
end
