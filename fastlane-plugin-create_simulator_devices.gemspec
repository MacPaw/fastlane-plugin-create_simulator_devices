# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/create_simulator_devices/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-create_simulator_devices'
  spec.version       = Fastlane::CreateSimulatorDevices::VERSION
  spec.author        = 'Vitalii Budnik'
  spec.email         = 'developers@setapp.com'

  spec.summary       = 'Fastlane plugin to create simulator devices'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*'] + %w[README.md LICENSE]
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 3.1.1'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
end
