# frozen_string_literal: true

module Fastlane
  module CreateSimulatorDevices
    module SimCTL
      # Represents a device type.
      class DeviceType
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

# Example of a device type object from `xcrun simctl list devicetypes --json` output:
#
# {
#   "productFamily" : "iPhone",
#   "bundlePath" : "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPod touch (7th generation).simdevicetype",
#   "maxRuntimeVersion" : 1048575,
#   "maxRuntimeVersionString" : "15.255.255",
#   "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPod-touch--7th-generation-",
#   "modelIdentifier" : "iPod9,1",
#   "minRuntimeVersionString" : "12.3.1",
#   "minRuntimeVersion" : 787201,
#   "name" : "iPod touch (7th generation)"
# }
