# frozen_string_literal: true

require_relative 'lib/vault/sync/version'
require 'rake/file_list'

Gem::Specification.new do |spec|
  spec.name          = 'vault-sync'
  spec.version       = Vault::Sync::VERSION
  spec.authors       = ['Jeff Byrnes']
  spec.email         = ['thejeffbyrnes@gmail.com']

  spec.summary       = 'CLI tool to sync KV secrets from one HashiCorp Vault to another.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/jeffbyrnes/vault-sync'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Rake::FileList['{exe,lib}/**/*', 'LICENSE.txt', 'README.md']
               .exclude(*File.read('.gitignore').split)

  spec.test_files    = Dir.glob('spec/*')
  spec.bindir        = 'exe'
  spec.executables   = Dir.glob('exe/*').map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_development_dependency 'pry', '~> 0.14.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.7'
  spec.add_development_dependency 'rubocop-packaging', '~> 0.5.1'
  spec.add_development_dependency 'rubocop-performance', '~> 1.9'
  spec.add_development_dependency 'rubocop-rake', '~> 0.5.1'
end
