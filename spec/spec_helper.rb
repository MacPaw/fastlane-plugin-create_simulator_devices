# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/create_simulator_devices' # import the actual plugin
require 'rspec'

# SimpleCov.minimum_coverage 95
SimpleCov.start do
  enable_coverage_for_eval

  add_group 'Models', 'lib/fastlane/plugin/create_simulator_devices/helpers/create_simulator_devices/models'
  add_group 'Helpers', 'lib/fastlane/plugin/create_simulator_devices/helpers'
  add_group 'Actions', 'lib/fastlane/plugin/create_simulator_devices/actions'
end

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)
