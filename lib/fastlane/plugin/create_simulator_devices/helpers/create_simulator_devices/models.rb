# frozen_string_literal: true

require_relative 'models/simctl/device_type'
require_relative 'models/simctl/device'
require_relative 'models/simctl/runtime'
require_relative 'models/simctl/runtime_supported_device_type'
require_relative 'models/xcodebuild/sdk'
require_relative 'models/required_device'
require_relative 'models/required_runtime'
require_relative 'models/apple_build_version'
require_relative 'models/device_naming_style'
require_relative 'models/simctl/matched_runtime'
require 'fastlane'

module Fastlane
  # Create simulator devices.
  module CreateSimulatorDevices
    UI = ::Fastlane::UI unless defined?(UI)
  end
end
