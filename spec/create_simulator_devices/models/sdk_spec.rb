# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Fastlane::CreateSimulatorDevices::Xcodebuild::SDK do
  describe '.from_hash' do
    it 'parses SDK from JSON string' do
      # GIVEN: A JSON string representing a single SDK object from `xcrun xcodebuild -showsdks -json` output
      json_string = <<~JSON
        {
          "buildID": "F8821DD8-570E-11F0-99A4-5B96CBB013DB",
          "canonicalName": "watchsimulator26.0",
          "displayName": "Simulator - watchOS 26.0",
          "isBaseSdk": true,
          "platform": "watchsimulator",
          "platformPath": "/Applications/Xcode_26_beta_3.app/Contents/Developer/Platforms/WatchSimulator.platform",
          "platformVersion": "26.0",
          "productBuildVersion": "23R5307e",
          "productCopyright": "1983-2025 Apple Inc.",
          "productName": "Watch OS",
          "productVersion": "26.0",
          "sdkPath": "/Applications/Xcode_26_beta_3.app/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator26.0.sdk",
          "sdkVersion": "26.0"
        }
      JSON

      # WHEN: Parsing the JSON and creating SDK from hash
      parsed_json = JSON.parse(json_string, symbolize_names: true)

      sut = described_class.from_hash(parsed_json)

      # THEN: SDK should be properly initialized
      expect(sut).to be_a(described_class)
      expect(sut.build_id).to eq('F8821DD8-570E-11F0-99A4-5B96CBB013DB')
      expect(sut.canonical_name).to eq('watchsimulator26.0')
      expect(sut.display_name).to eq('Simulator - watchOS 26.0')
      expect(sut.platform).to eq('watchsimulator')
      expect(sut.platform_version).to eq('26.0')
      expect(sut.product_build_version).to eql('23R5307e')
      expect(sut.sdk_version).to eq('26.0')
      expect(sut.simulator?).to be_truthy
    end
  end

  describe '.simulator?' do
    it 'returns true for simulator platforms' do
      # GIVEN: A SDK with a simulator platform
      sut = described_class.new(build_id: nil, canonical_name: nil, display_name: nil, platform: 'watchsimulator', platform_version: nil, sdk_version: nil, product_name: nil, product_version: nil, product_build_version: nil)

      # THEN: The SDK should be a simulator
      expect(sut.simulator?).to be_truthy
    end

    it 'returns false for non-simulator platforms' do
      # GIVEN: A SDK with a non-simulator platform
      sut = described_class.new(build_id: nil, canonical_name: nil, display_name: nil, platform: 'watchsos', platform_version: nil, sdk_version: nil, product_name: nil, product_version: nil, product_build_version: nil)

      # THEN: The SDK should not be a simulator
      expect(sut.simulator?).to be_falsey
    end
  end
end
