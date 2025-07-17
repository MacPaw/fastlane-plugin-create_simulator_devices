# frozen_string_literal: true

require_relative '../../spec_helper'
require 'rspec'

RSpec.describe Fastlane::CreateSimulatorDevices::SimCTL::Runtime do
  describe '.from_hash' do
    it 'parses runtime from JSON string' do
      # GIVEN: A JSON string representing a single runtime object from `xcrun simctl list runtimes --json` output
      json_string = <<~JSON
        {
          "isAvailable": true,
          "version": "17.4",
          "isInternal": false,
          "buildversion" : "23M5279f",
          "supportedArchitectures" : [
            "arm64"
          ],
          "supportedDeviceTypes": [
            {
              "bundlePath": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 15.simdevicetype",
              "name": "iPhone 15",
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
              "productFamily": "iPhone"
            },
            {
              "bundlePath": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 15 Pro.simdevicetype",
              "name": "iPhone 15 Pro",
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
              "productFamily": "iPhone"
            }
          ],
          "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-17-4",
          "platform": "iOS",
          "bundlePath": "",
          "runtimeRoot": "",
          "lastUsage": {
            "arm64" : "0001-01-01T00:00:00Z"
          },
          "name": "iOS 17.4"
        }
      JSON

      # WHEN: Parsing the JSON and creating Runtime from hash
      parsed_json = JSON.parse(json_string, symbolize_names: true)

      sut = described_class.from_hash(parsed_json)

      # THEN: Runtime should be properly initialized with all attributes
      expect(sut).to be_a(described_class)
      expect(sut.identifier).to eq('com.apple.CoreSimulator.SimRuntime.iOS-17-4')
      expect(sut.platform).to eq('iOS')
      expect(sut.version).to eq(Gem::Version.new('17.4'))
      expect(sut.build_version).to eql('23M5279f')
      expect(sut.supported_device_types.size).to eq(2)
      expect(sut.supported_device_types.first).to be_a(Fastlane::CreateSimulatorDevices::SimCTL::Runtime::SupportedDeviceType)
      expect(sut.supported_device_types.first.identifier).to eq('com.apple.CoreSimulator.SimDeviceType.iPhone-15')
      expect(sut.supported_device_types.last.identifier).to eq('com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro')
    end
  end
end
