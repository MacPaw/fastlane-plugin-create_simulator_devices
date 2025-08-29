# frozen_string_literal: true

require_relative '../spec_helper'
require 'fastlane'
require 'rspec'

RSpec.describe Fastlane::CreateSimulatorDevices::RuntimeHelper do
  AppleBuildVersion = Fastlane::CreateSimulatorDevices::AppleBuildVersion
  RequiredRuntime = Fastlane::CreateSimulatorDevices::RequiredRuntime
  RequiredDevice = Fastlane::CreateSimulatorDevices::RequiredDevice
  SimCTL = Fastlane::CreateSimulatorDevices::SimCTL
  Xcodebuild = Fastlane::CreateSimulatorDevices::Xcodebuild
  Xcodebuild_SDK = Fastlane::CreateSimulatorDevices::Xcodebuild::SDK
  RuntimeWithState = Fastlane::CreateSimulatorDevices::SimCTL::RuntimeWithState
  Runtime = Fastlane::CreateSimulatorDevices::SimCTL::Runtime
  Runtime_SupportedDeviceType = Fastlane::CreateSimulatorDevices::SimCTL::Runtime::SupportedDeviceType
  DeviceType = Fastlane::CreateSimulatorDevices::SimCTL::DeviceType

  let(:cache_dir) { '/tmp/test_cache' }
  let(:shell_helper) { instance_double(Fastlane::CreateSimulatorDevices::ShellHelper) }
  let(:sut) { described_class.new(cache_dir:, shell_helper:, verbose: false) }

  describe '#initialize' do
    it 'initializes with cache_dir, shell_helper, and verbose' do
      # GIVEN: Constructor parameters
      cache_dir = '/custom/cache'
      shell_helper = instance_double(Fastlane::CreateSimulatorDevices::ShellHelper)
      verbose = true

      # WHEN: Creating a new RuntimeHelper instance
      runtime_helper = described_class.new(cache_dir:, shell_helper:, verbose:)

      # THEN: The instance should be properly initialized
      expect(runtime_helper.cache_dir).to eq(cache_dir)
      expect(runtime_helper.shell_helper).to eq(shell_helper)
      expect(runtime_helper.verbose).to eq(verbose)
    end
  end

  describe '#delete_unusable_runtimes' do
    it 'deletes unusable and deletable runtimes' do
      # GIVEN: Mock runtimes with some unusable and deletable
      unusable_runtime = instance_double(RuntimeWithState, unusable?: true, deletable?: true, identifier: 'unusable-runtime')
      usable_runtime = instance_double(RuntimeWithState, unusable?: false, deletable?: true, identifier: 'usable-runtime')
      unusable_but_not_deletable = instance_double(RuntimeWithState, unusable?: true, deletable?: false, identifier: 'unusable-not-deletable')

      runtimes = [unusable_runtime, usable_runtime, unusable_but_not_deletable]

      allow(shell_helper).to receive(:installed_runtimes_with_state).and_return(runtimes)
      allow(shell_helper).to receive(:delete_runtime)
      allow(shell_helper).to receive(:simctl_runtimes)
      allow(shell_helper).to receive(:simctl_devices_for_runtimes)

      # WHEN: Deleting unusable runtimes
      sut.delete_unusable_runtimes

      # THEN: Only the unusable and deletable runtime should be deleted
      expect(shell_helper).to have_received(:delete_runtime).with('unusable-runtime')
      expect(shell_helper).not_to have_received(:delete_runtime).with('usable-runtime')
      expect(shell_helper).not_to have_received(:delete_runtime).with('unusable-not-deletable')
      expect(shell_helper).to have_received(:simctl_runtimes).with(force: true)
      expect(shell_helper).to have_received(:simctl_devices_for_runtimes).with(force: true)
    end
  end

  describe '#missing_runtimes' do
    it 'returns runtimes that are not available' do
      # GIVEN: Needed runtimes with one missing
      needed_runtime1 = instance_double(RequiredRuntime, os_name: 'iOS', product_version: '17.0')
      needed_runtime2 = instance_double(RequiredRuntime, os_name: 'iOS', product_version: '18.0')
      needed_runtimes = [needed_runtime1, needed_runtime2]

      allow(sut).to receive(:simctl_runtime_matching_needed_runtime?).with(needed_runtime1).and_return(nil)
      allow(sut).to receive(:simctl_runtime_matching_needed_runtime?).with(needed_runtime2).and_return(instance_double(Runtime))

      # WHEN: Finding missing runtimes
      result = sut.missing_runtimes(needed_runtimes)

      # THEN: Should return only the missing runtime
      expect(result).to eq([needed_runtime1])
    end
  end

  describe '#simctl_runtime_matching_needed_runtime?' do
    it 'returns matching runtime when found' do
      # GIVEN: A needed runtime and matching available runtime
      needed_runtime = instance_double(RequiredRuntime,
                                       os_name: 'iOS',
                                       product_version: Gem::Version.new('17.0'),
                                       product_build_version: AppleBuildVersion.new('21A326'))

      simctl_runtime = instance_double(Runtime,
                                       platform: 'iOS',
                                       version: Gem::Version.new('17.0.1'),
                                       build_version: AppleBuildVersion.new('21A457'))

      allow(shell_helper).to receive(:simctl_runtimes).and_return([simctl_runtime])
      allow(needed_runtime).to receive(:product_build_version=)
      allow(needed_runtime).to receive(:product_build_version).and_return(AppleBuildVersion.new('21A326'))
      allow(needed_runtime).to receive(:product_version=).with(Gem::Version.new('17.0.1'))

      build_version = AppleBuildVersion.new('21A457')
      allow(build_version).to receive(:almost_equal?).with(AppleBuildVersion.new('21A457')).and_return(true)
      allow(needed_runtime).to receive(:product_build_version).and_return(build_version)

      # WHEN: Finding matching runtime
      result = sut.simctl_runtime_matching_needed_runtime?(needed_runtime)

      # THEN: Should return the matching runtime
      expect(result).to eq(simctl_runtime)
    end

    it 'returns nil when no matching runtime found' do
      # GIVEN: A needed runtime with no matching available runtime
      needed_runtime = instance_double(RequiredRuntime, os_name: 'iOS', product_version: '17.0')
      simctl_runtime = instance_double(Runtime, platform: 'watchOS', version: '10.0')

      allow(shell_helper).to receive(:simctl_runtimes).and_return([simctl_runtime])

      # WHEN: Finding matching runtime
      result = sut.simctl_runtime_matching_needed_runtime?(needed_runtime)

      # THEN: Should return nil
      expect(result).to be_nil
    end
  end

  describe '#simctl_runtime_for_required_device' do
    let(:device_type) { instance_double(DeviceType, name: 'iPhone 15', identifier: 'com.apple.CoreSimulator.SimDeviceType.iPhone-15') }
    let(:required_runtime) { instance_double(RequiredRuntime, description: 'iOS 17.0') }
    let(:required_device) { instance_double(RequiredDevice, required_runtime:, device_type:, description: 'iPhone 15 (17.0)') }

    it 'returns available runtime when device type is supported' do
      # GIVEN: A required device with supported device type
      supported_device_type = instance_double(Runtime_SupportedDeviceType, identifier: 'com.apple.CoreSimulator.SimDeviceType.iPhone-15')
      simctl_runtime = instance_double(Runtime,
                                       identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-17-0',
                                       supported_device_types: [supported_device_type])

      allow(sut).to receive(:simctl_runtime_matching_needed_runtime?).with(required_runtime).and_return(simctl_runtime)

      # WHEN: Finding available runtime for required device
      result = sut.simctl_runtime_for_required_device(required_device)

      # THEN: Should return the available runtime
      expect(result).to eq(simctl_runtime)
    end

    it 'returns nil when runtime is not found' do
      # GIVEN: A required device with no matching runtime
      allow(sut).to receive(:simctl_runtime_matching_needed_runtime?).with(required_runtime).and_return(nil)
      allow(Fastlane::UI).to receive(:important)

      # WHEN: Finding available runtime for required device
      result = sut.simctl_runtime_for_required_device(required_device)

      # THEN: Should return nil and log warning
      expect(result).to be_nil
      expect(Fastlane::UI).to have_received(:important).with(/Runtime .* not found/)
    end

    it 'returns nil when device type is not supported by runtime' do
      # GIVEN: A required device with unsupported device type
      supported_device_type = instance_double(Runtime_SupportedDeviceType, identifier: 'com.apple.CoreSimulator.SimDeviceType.iPhone-14')
      simctl_runtime = instance_double(Runtime,
                                       identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-17-0',
                                       supported_device_types: [supported_device_type])

      allow(sut).to receive(:simctl_runtime_matching_needed_runtime?).with(required_runtime).and_return(simctl_runtime)
      allow(Fastlane::UI).to receive(:important)

      # WHEN: Finding available runtime for required device
      result = sut.simctl_runtime_for_required_device(required_device)

      # THEN: Should return nil and log warning
      expect(result).to be_nil
      expect(Fastlane::UI).to have_received(:important).with(/Device type .* is not supported by runtime/)
    end
  end

  describe '#download_and_install_missing_runtime' do
    it 'downloads and installs runtime when not cached' do
      # GIVEN: Missing runtime not in cache
      missing_runtime = instance_double(RequiredRuntime, runtime_name: 'iOS 17.0')

      allow(sut).to receive(:cached_runtime_file).and_return(nil, '/tmp/downloaded_runtime.dmg')
      allow(shell_helper).to receive(:download_runtime)
      allow(shell_helper).to receive(:import_runtime)
      allow(Fastlane::UI).to receive(:message)

      # WHEN: Downloading and installing missing runtime
      sut.download_and_install_missing_runtime(missing_runtime)

      # THEN: Should download and then install
      expect(shell_helper).to have_received(:download_runtime).with(missing_runtime, cache_dir)
      expect(shell_helper).to have_received(:import_runtime).with('/tmp/downloaded_runtime.dmg', 'iOS 17.0')
      expect(Fastlane::UI).to have_received(:message).with('Attempting to install iOS 17.0 runtime.')
    end

    it 'installs runtime when already cached' do
      # GIVEN: Missing runtime already in cache
      missing_runtime = instance_double(RequiredRuntime, runtime_name: 'iOS 17.0')
      cached_file = '/tmp/cached_runtime.dmg'

      allow(sut).to receive(:cached_runtime_file).and_return(cached_file)
      allow(shell_helper).to receive(:download_runtime)
      allow(shell_helper).to receive(:import_runtime)
      allow(Fastlane::UI).to receive(:message)

      # WHEN: Downloading and installing missing runtime
      sut.download_and_install_missing_runtime(missing_runtime)

      # THEN: Should not download but should install
      expect(shell_helper).not_to have_received(:download_runtime)
      expect(shell_helper).to have_received(:import_runtime).with(cached_file, 'iOS 17.0')
      expect(Fastlane::UI).to have_received(:message).with('Attempting to install iOS 17.0 runtime.')
    end
  end

  describe '#runtime_build_version_for_filename' do
    it 'extracts build version from filename' do
      # GIVEN: A runtime filename
      filename = '/tmp/iphonesimulator_17.0_21A326.dmg'

      allow(AppleBuildVersion).to receive(:new).with('21A326').and_return(AppleBuildVersion.new('21A326'))

      # WHEN: Extracting build version
      result = sut.runtime_build_version_for_filename(filename)

      # THEN: Should return the build version
      expect(result).to be_a(AppleBuildVersion)
      expect(AppleBuildVersion).to have_received(:new).with('21A326')
    end
  end

  describe '#cached_runtime_file' do
    it 'returns existing cached file when found' do
      # GIVEN: A missing runtime and existing cached file
      missing_runtime = instance_double(RequiredRuntime,
                                        sdk_platform: 'iphonesimulator',
                                        product_version: '17.0',
                                        product_build_version: AppleBuildVersion.new('21A326'),
                                        runtime_name: 'iOS 17.0')

      existing_file = '/tmp/test_cache/iphonesimulator_17.0.1_21A326.dmg'

      allow(FileUtils).to receive(:mkdir_p).with(cache_dir)
      allow(Dir).to receive(:glob).with('/tmp/test_cache/iphonesimulator_17.0*_21A326*.dmg').and_return([existing_file])
      allow(sut).to receive(:runtime_build_version_for_filename).and_return(AppleBuildVersion.new('21A326'))
      allow(Fastlane::UI).to receive(:message)

      # WHEN: Finding cached runtime file
      result = sut.cached_runtime_file(missing_runtime)

      # THEN: Should return the existing file
      expect(result).to eq(existing_file)
      expect(Fastlane::UI).to have_received(:message).with("Found existing iOS 17.0 runtime image in #{cache_dir}: #{existing_file}")
    end

    it 'returns nil when no cached file found' do
      # GIVEN: A missing runtime with no cached file
      missing_runtime = instance_double(RequiredRuntime,
                                        sdk_platform: 'iphonesimulator',
                                        product_version: '17.0',
                                        product_build_version: AppleBuildVersion.new('21A326'))

      allow(FileUtils).to receive(:mkdir_p).with(cache_dir)
      allow(Dir).to receive(:glob).and_return([])

      # WHEN: Finding cached runtime file
      result = sut.cached_runtime_file(missing_runtime)

      # THEN: Should return nil
      expect(result).to be_nil
    end
  end

  describe '#required_runtime_for_device' do
    let(:device_type) { instance_double(DeviceType, name: 'iPhone 15') }
    let(:required_device) { instance_double(RequiredDevice, device_type:, os_name: 'iOS') }

    it 'creates required runtime for device with specific version' do
      # GIVEN: A required device and runtime version
      runtime_version = Gem::Version.new('17.0')
      sdk = instance_double(Xcodebuild_SDK,
                            platform: 'iphonesimulator',
                            product_version: Gem::Version.new('17.2'),
                            product_build_version: AppleBuildVersion.new('21C52'))

      allow(sut).to receive(:max_xcodebuild_simulator_sdks).and_return({ 'iOS' => sdk })
      allow(RequiredRuntime).to receive(:new).and_return(instance_double(RequiredRuntime))
      allow(AppleBuildVersion).to receive(:new).with('21C52').and_return(AppleBuildVersion.new('21C52'))

      build_version = AppleBuildVersion.new('21C52')
      allow(build_version).to receive(:almost_equal?).with(nil).and_return(false)

      # WHEN: Creating required runtime
      sut.required_runtime_for_device(required_device, runtime_version)

      # THEN: Should create required runtime with correct parameters
      expect(RequiredRuntime).to have_received(:new).with(
        sdk_platform: 'iphonesimulator',
        os_name: 'iOS',
        product_version: runtime_version,
        product_build_version: nil,
        is_latest: false
      )
    end

    it 'returns nil when runtime version is higher than SDK' do
      # GIVEN: A required device and runtime version higher than SDK
      runtime_version = Gem::Version.new('18.0')
      sdk = instance_double(Xcodebuild_SDK,
                            platform: 'iphonesimulator',
                            product_version: Gem::Version.new('17.2'))

      allow(sut).to receive(:max_xcodebuild_simulator_sdks).and_return({ 'iOS' => sdk })
      allow(Fastlane::UI).to receive(:important)

      # WHEN: Creating required runtime
      result = sut.required_runtime_for_device(required_device, runtime_version)

      # THEN: Should return nil and log warning
      expect(result).to be_nil
      expect(Fastlane::UI).to have_received(:important).with(/Runtime version .* is higher than maximum supported/)
    end

    it 'uses SDK build version when runtime version matches SDK version' do
      # GIVEN: A required device and runtime version matching SDK
      runtime_version = Gem::Version.new('17.2')
      sdk = instance_double(Xcodebuild_SDK,
                            platform: 'iphonesimulator',
                            product_version: Gem::Version.new('17.2'),
                            product_build_version: AppleBuildVersion.new('21C52'))

      allow(sut).to receive(:max_xcodebuild_simulator_sdks).and_return({ 'iOS' => sdk })
      allow(RequiredRuntime).to receive(:new).and_return(instance_double(RequiredRuntime))

      build_version = AppleBuildVersion.new('21C52')
      allow(build_version).to receive(:almost_equal?).with(AppleBuildVersion.new('21C52')).and_return(true)

      # WHEN: Creating required runtime
      sut.required_runtime_for_device(required_device, runtime_version)

      # THEN: Should use SDK build version
      expect(RequiredRuntime).to have_received(:new).with(
        sdk_platform: 'iphonesimulator',
        os_name: 'iOS',
        product_version: runtime_version,
        product_build_version: AppleBuildVersion.new('21C52'),
        is_latest: true
      )
    end
  end

  describe '#max_xcodebuild_simulator_sdks' do
    it 'returns cached result on subsequent calls' do
      # GIVEN: Already cached SDK data
      cached_sdks = { 'iOS' => instance_double(Xcodebuild_SDK) }
      sut.instance_variable_set(:@max_xcodebuild_simulator_sdks, cached_sdks)

      # WHEN: Calling max_xcodebuild_simulator_sdks
      result = sut.max_xcodebuild_simulator_sdks

      # THEN: Should return cached result
      expect(result).to eq(cached_sdks)
    end

    it 'calculates and caches SDK data on first call' do
      # GIVEN: Available SDKs from shell helper
      ios_sdk = instance_double(Xcodebuild_SDK,
                                platform: 'iphonesimulator',
                                product_version: Gem::Version.new('17.2'))
      tvos_sdk = instance_double(Xcodebuild_SDK,
                                 platform: 'appletvsimulator',
                                 product_version: Gem::Version.new('17.2'))
      macos_sdk = instance_double(Xcodebuild_SDK,
                                  platform: 'macosx',
                                  product_version: Gem::Version.new('14.2'))

      all_sdks = [ios_sdk, tvos_sdk, macos_sdk]
      allow(shell_helper).to receive(:xcodebuild_sdks).and_return(all_sdks)

      # WHEN: Calling max_xcodebuild_simulator_sdks
      result = sut.max_xcodebuild_simulator_sdks

      # THEN: Should return filtered and organized SDK data
      expect(result).to be_a(Hash)
      expect(result['iOS']).to eq(ios_sdk)
      expect(result['tvOS']).to eq(tvos_sdk)
      expect(result['macOS']).to be_nil # macosx is not a simulator platform
    end

    it 'selects maximum version for each platform' do
      # GIVEN: Multiple SDKs for same platform with different versions
      ios_sdk_old = instance_double(Xcodebuild_SDK,
                                    platform: 'iphonesimulator',
                                    product_version: Gem::Version.new('16.0'))
      ios_sdk_new = instance_double(Xcodebuild_SDK,
                                    platform: 'iphonesimulator',
                                    product_version: Gem::Version.new('17.2'))

      all_sdks = [ios_sdk_old, ios_sdk_new]
      allow(shell_helper).to receive(:xcodebuild_sdks).and_return(all_sdks)

      # WHEN: Calling max_xcodebuild_simulator_sdks
      result = sut.max_xcodebuild_simulator_sdks

      # THEN: Should return the newer SDK version
      expect(result['iOS']).to eq(ios_sdk_new)
    end
  end
end
