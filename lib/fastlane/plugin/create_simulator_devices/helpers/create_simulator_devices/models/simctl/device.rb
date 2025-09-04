# frozen_string_literal: true

module Fastlane
  module CreateSimulatorDevices
    module SimCTL
      # Represents a device.
      class Device
        attr_accessor :udid, :name, :device_type_identifier, :available, :data_path, :log_path

        def initialize(name:, udid:, device_type_identifier:, available:, data_path:, log_path:) # rubocop:disable Metrics/ParameterLists
          self.name = name
          self.udid = udid
          self.device_type_identifier = device_type_identifier
          self.available = available
          self.data_path = data_path
          self.log_path = log_path
        end

        def available?
          available
        end

        def description
          "#{name} (#{device_type_identifier}, #{udid})"
        end

        def self.from_hash(hash)
          new(
            name: hash[:name],
            udid: hash[:udid],
            device_type_identifier: hash[:deviceTypeIdentifier],
            available: hash[:isAvailable],
            data_path: hash[:dataPath],
            log_path: hash[:logPath]
          )
        end
      end
    end
  end
end

# Example of a device object from `xcrun simctl list devices --json` output:
#
# {
#   "dataPath": "/Users/username/Library/Developer/CoreSimulator/Devices/1C1796E3-AB33-41AB-B3EB-9836CF39E57B/data",
#   "dataPathSize": 4096,
#   "logPath": "/Users/username/Library/Logs/CoreSimulator/1C1796E3-AB33-41AB-B3EB-9836CF39E57B",
#   "udid": "1C1796E3-AB33-41AB-B3EB-9836CF39E57B",
#   "isAvailable": true,
#   "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p",
#   "state": "Shutdown",
#   "name": "Apple TV"
# }
