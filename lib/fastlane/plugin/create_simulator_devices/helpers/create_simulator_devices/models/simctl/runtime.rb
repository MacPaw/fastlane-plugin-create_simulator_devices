# frozen_string_literal: true

require_relative 'runtime_supported_device_type'
require_relative '../apple_build_version'

module Fastlane
  module CreateSimulatorDevices
    module SimCTL
      # Represents a runtime from `xcrun simctl runtime list --json` output.
      class RuntimeWithState
        attr_accessor :identifier, :version, :build, :state, :deletable, :runtime_identifier

        def initialize(identifier:, version:, build:, state:, deletable:, runtime_identifier:) # rubocop:disable Metrics/ParameterLists
          self.identifier = identifier
          self.version = version
          self.build = build
          self.state = state
          self.deletable = deletable
          self.runtime_identifier = runtime_identifier
        end

        def ready?
          state == 'Ready'
        end

        def deletable?
          deletable
        end

        def unusable?
          state == 'Unusable'
        end

        def self.from_hash(hash)
          new(
            identifier: hash[:identifier].to_s,
            version: Gem::Version.new(hash[:version]),
            build: AppleBuildVersion.new(hash[:build]),
            state: hash[:state].to_s,
            deletable: hash[:deletable],
            runtime_identifier: hash[:runtimeIdentifier].to_s
          )
        end
      end

      # Represents a runtime from `xcrun simctl list runtimes --json` output.
      class Runtime
        attr_accessor :identifier, :platform, :version, :supported_device_types, :build_version, :is_available

        def initialize(identifier:, platform:, version:, supported_device_types:, build_version:, is_available:) # rubocop:disable Metrics/ParameterLists
          self.identifier = identifier
          self.platform = platform
          self.version = version
          self.supported_device_types = supported_device_types
          self.build_version = build_version
          self.is_available = is_available
        end

        def self.from_hash(hash)
          build_version = AppleBuildVersion.new(hash[:buildversion]) if hash[:buildversion]

          new(
            identifier: hash[:identifier],
            platform: hash[:platform],
            version: Gem::Version.new(hash[:version]),
            supported_device_types: hash[:supportedDeviceTypes].map { |device_type| Runtime::SupportedDeviceType.from_hash(device_type) },
            build_version:,
            is_available: hash[:isAvailable]
          )
        end

        def runtime_name
          "#{[platform, version].join(' ')} (build #{build_version})"
        end

        def available?
          is_available
        end
      end
    end
  end
end

# Example of a Runtime object from `xcrun simctl list runtimes --json` output:
#
# {
#   "isAvailable": true,
#   "version": "17.4",
#   "isInternal": false,
#   "buildversion" : "23M5279f",
#   "supportedArchitectures" : [
#     "arm64"
#   ],
#   "supportedDeviceTypes": [
#     {
#       "bundlePath": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 15.simdevicetype",
#       "name": "iPhone 15",
#       "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
#       "productFamily": "iPhone"
#     },
#     {
#       "bundlePath": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 15 Pro.simdevicetype",
#       "name": "iPhone 15 Pro",
#       "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
#       "productFamily": "iPhone"
#     }
#   ],
#   "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-17-4",
#   "platform": "iOS",
#   "bundlePath": "",
#   "runtimeRoot": "",
#   "lastUsage": {
#     "arm64" : "0001-01-01T00:00:00Z"
#   },
#   "name": "iOS 17.4"
# }
