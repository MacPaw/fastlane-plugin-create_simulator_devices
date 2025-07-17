# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Fastlane::CreateSimulatorDevices::SimCTL::Device do
  describe '.from_hash' do
    it 'parses device from JSON string' do
      # GIVEN: A JSON string representing a single device object from `xcrun simctl list devices --json` output
      json_string = <<~JSON
        {
          "dataPath": "/Users/username/Library/Developer/CoreSimulator/Devices/24BB418C-CC81-4C40-8D9A-C48A4B42D9CE/data",
          "dataPathSize": 4096,
          "logPath": "/Users/username/Library/Logs/CoreSimulator/24BB418C-CC81-4C40-8D9A-C48A4B42D9CE",
          "udid": "24BB418C-CC81-4C40-8D9A-C48A4B42D9CE",
          "isAvailable": true,
          "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-4K",
          "state": "Shutdown",
          "name": "Apple TV 4K (3rd generation)"
        }
      JSON

      # WHEN: Parsing the JSON and creating Device from hash
      parsed_json = JSON.parse(json_string, symbolize_names: true)

      sut = described_class.from_hash(parsed_json)

      # THEN: Device should be properly initialized
      expect(sut).to be_a(described_class)
      expect(sut.udid).to eq('24BB418C-CC81-4C40-8D9A-C48A4B42D9CE')
      expect(sut.name).to eq('Apple TV 4K (3rd generation)')
      expect(sut.device_type_identifier).to eq('com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-4K')
      expect(sut.available).to be_truthy
    end
  end
end
