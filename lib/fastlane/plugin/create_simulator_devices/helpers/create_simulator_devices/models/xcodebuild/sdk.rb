# frozen_string_literal: true

require_relative '../apple_build_version'

module Fastlane
  module CreateSimulatorDevices
    module Xcodebuild
      # Represents a SDK.
      class SDK
        attr_accessor :build_id, :canonical_name, :display_name, :platform, :platform_version, :product_build_version, :sdk_version, :product_name, :product_version

        def initialize(build_id:, canonical_name:, display_name:, platform:, platform_version:, sdk_version:, product_name:, product_version:, product_build_version:) # rubocop:disable Metrics/ParameterLists
          self.build_id = build_id
          self.canonical_name = canonical_name
          self.display_name = display_name
          self.platform = platform
          self.platform_version = platform_version
          self.sdk_version = sdk_version
          self.product_name = product_name
          self.product_version = product_version
          self.product_build_version = product_build_version
        end

        def self.from_hash(hash)
          product_version = Gem::Version.new(hash[:productVersion]) if hash[:productVersion]
          new(
            build_id: hash[:buildID],
            canonical_name: hash[:canonicalName],
            display_name: hash[:displayName],
            platform: hash[:platform],
            platform_version: Gem::Version.new(hash[:platformVersion]),
            sdk_version: Gem::Version.new(hash[:sdkVersion]),
            product_name: hash[:productName],
            product_version: product_version,
            product_build_version: AppleBuildVersion.new(hash[:productBuildVersion])
          )
        end

        def simulator?
          platform.end_with?('simulator')
        end
      end
    end
  end
end

# Example of a SDK object from `xcrun xcodebuild -showsdks -json` output:
#
# {
#   "buildID": "F8821DD8-570E-11F0-99A4-5B96CBB013DB",
#   "canonicalName": "watchsimulator26.0",
#   "displayName": "Simulator - watchOS 26.0",
#   "isBaseSdk": true,
#   "platform": "watchsimulator",
#   "platformPath": "/Applications/Xcode_26_beta_3.app/Contents/Developer/Platforms/WatchSimulator.platform",
#   "platformVersion": "26.0",
#   "productBuildVersion": "23R5307e",
#   "productCopyright": "1983-2025 Apple Inc.",
#   "productName": "Watch OS",
#   "productVersion": "26.0",
#   "sdkPath": "/Applications/Xcode_26_beta_3.app/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator26.0.sdk",
#   "sdkVersion": "26.0"
# }
