# frozen_string_literal: true

module Fastlane
  module CreateSimulatorDevices
    module SimCTL
      class Runtime
        # Represents a supported device type by a runtime.
        class SupportedDeviceType
          attr_accessor :identifier, :name, :product_family

          def initialize(identifier:, name:, product_family:)
            self.identifier = identifier
            self.name = name
            self.product_family = product_family
          end

          def self.from_hash(hash)
            new(identifier: hash[:identifier], name: hash[:name], product_family: hash[:productFamily])
          end
        end
      end
    end
  end
end

# Example of a supported device type object from `xcrun simctl list runtimes --json` output:
#
# {
#   "bundlePath": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 15.simdevicetype",
#   "name": "iPhone 15",
#   "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
#   "productFamily": "iPhone"
# }
