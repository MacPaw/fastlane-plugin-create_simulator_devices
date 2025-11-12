# frozen_string_literal: true

require_relative 'runtime_supported_device_type'
require_relative '../apple_build_version'

module Fastlane
  module CreateSimulatorDevices
    module SimCTL
      # Represents a matched runtime from `xcrun simctl runtime match list --json` output.
      class MatchedRuntime
        attr_accessor :identifier, :default_build, :chosen_runtime_build, :sdk_build, :sdk_version, :platform

        def initialize(identifier:, default_build:, chosen_runtime_build:, sdk_build:, sdk_version:, platform:) # rubocop:disable Metrics/ParameterLists
          self.identifier = identifier
          self.default_build = default_build
          self.chosen_runtime_build = chosen_runtime_build
          self.sdk_build = sdk_build
          self.sdk_version = sdk_version
          self.platform = platform
        end

        def self.from_hash(hash, identifier:)
          new(
            identifier: identifier.to_s,
            default_build: AppleBuildVersion.new(hash[:defaultBuild]),
            chosen_runtime_build: AppleBuildVersion.new(hash[:chosenRuntimeBuild]),
            sdk_build: AppleBuildVersion.new(hash[:sdkBuild]),
            sdk_version: Gem::Version.new(hash[:sdkVersion]),
            platform: hash[:platform].to_s
          )
        end
      end
    end
  end
end

# Example of a Runtime object from `xcrun simctl list runtimes --json` output:
#
# {"iphoneos26.1" : {
#   "chosenRuntimeBuild" : "23B80",
#   "defaultBuild" : "23B77",
#   "platform" : "com.apple.platform.iphoneos",
#   "sdkBuild" : "23B77",
#   "sdkDirectory" : "\/Applications\/Xcode-26.1.1.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Developer\/SDKs\/iPhoneOS26.1.sdk",
#   "sdkVersion" : "26.1"
# }
