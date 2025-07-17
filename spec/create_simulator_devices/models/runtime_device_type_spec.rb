# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Fastlane::CreateSimulatorDevices::SimCTL::DeviceType do
  describe '.from_hash' do
    it 'parses device type from JSON string' do
      # GIVEN: A JSON string representing a single device type object from `xcrun simctl list devicetypes --json` output
      json_string = <<~JSON
        {
          "productFamily" : "Apple Watch",
          "bundlePath" : "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 2 (38mm).simdevicetype",
          "maxRuntimeVersion" : 458751,
          "maxRuntimeVersionString" : "6.255.255",
          "identifier" : "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-2-38mm",
          "modelIdentifier" : "Watch2,3",
          "minRuntimeVersionString" : "3.0.0",
          "minRuntimeVersion" : 196608,
          "name" : "Apple Watch Series 2 (38mm)"
        }
      JSON

      # WHEN: Parsing the JSON and creating DeviceType from hash
      parsed_json = JSON.parse(json_string, symbolize_names: true)
      sut = described_class.from_hash(parsed_json)

      # THEN: DeviceType should be properly initialized
      expect(sut).to be_a(described_class)
      expect(sut.identifier).to eq('com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-2-38mm')
      expect(sut.name).to eq('Apple Watch Series 2 (38mm)')
      expect(sut.product_family).to eq('Apple Watch')
    end
  end
end
