# frozen_string_literal: true

require 'fileutils'
require 'fastlane'
require_relative 'shell_helper'

module Fastlane
  module CreateSimulatorDevices
    # Helper class for managing simulator runtimes.
    class RuntimeHelper
      UI = ::Fastlane::UI unless defined?(UI)

      attr_accessor :cache_dir, :shell_helper, :verbose

      def initialize(cache_dir:, shell_helper:, verbose:)
        self.cache_dir = cache_dir
        self.shell_helper = shell_helper
        self.verbose = verbose
      end

      SDK_PLATFORM_TO_OS_NAME = {
        'iphonesimulator' => 'iOS',
        'appletvsimulator' => 'tvOS',
        'watchsimulator' => 'watchOS',
        'xrsimulator' => 'xrOS'
      }.freeze

      def delete_unusable_runtimes
        deletable_runtimes = shell_helper.installed_runtimes_with_state
          .select { |runtime| runtime.unusable? && runtime.deletable? }

        return if deletable_runtimes.empty?

        deletable_runtimes.each do |runtime|
          shell_helper.delete_runtime(runtime.identifier)
        end

        shell_helper.available_runtimes(force: true)
        shell_helper.available_devices_for_runtimes(force: true)
      end

      def install_missing_runtimes(required_devices)
        needed_runtimes = required_devices.filter_map(&:required_runtime).uniq

        missing_runtimes = missing_runtimes(needed_runtimes)

        if missing_runtimes.empty?
          UI.message('All required runtimes are present. Skipping runtime installation...') if verbose
          return
        end

        missing_runtimes.each do |missing_runtime|
          download_and_install_missing_runtime(missing_runtime)
        end

        # Update available_runtimes after installing the runtimes.
        shell_helper.installed_runtimes_with_state
        shell_helper.available_runtimes(force: true)
        shell_helper.available_devices_for_runtimes(force: true)

        # Check if missing runtimes are available after installing
        missing_runtimes = missing_runtimes(missing_runtimes)

        # List missing runtimes after attempt to install the runtimes.
        missing_runtimes(missing_runtimes)
          .each do |missing_runtime|
            UI.important("Failed to find/download/install runtime #{missing_runtime.runtime_name}")
          end
      end

      def missing_runtimes(needed_runtimes)
        needed_runtimes.select do |needed_runtime|
          # Check if available runtimes contain the needed runtime.
          available_runtime_matching_needed_runtime?(needed_runtime).nil?
        end
      end

      def available_runtime_matching_needed_runtime?(needed_runtime)
        matching_runtimes = shell_helper.available_runtimes
          .select do |available_runtime|
            next false if needed_runtime.os_name != available_runtime.platform

            # If the product version is not equal, check if the first two segments are equal.
            is_product_version_equal = if needed_runtime.product_version == available_runtime.version
                                         true
                                       else
                                         lhs_segments = needed_runtime.product_version.segments
                                         rhs_segments = available_runtime.version.segments
                                         if rhs_segments.size == 3
                                           lhs_segments[0] == rhs_segments[0] && lhs_segments[1] == rhs_segments[1]
                                         else
                                           false
                                         end
                                       end
            next false unless is_product_version_equal

            # If the product version is not equal, use the available runtime version.
            needed_runtime.product_version = available_runtime.version

            needed_runtime.product_build_version = [needed_runtime.product_build_version, available_runtime.build_version].compact.max

            needed_runtime.product_build_version.almost_equal?(available_runtime.build_version)
          end

        matching_runtimes.max_by { |available_runtime| [available_runtime.version, available_runtime.build_version] }
      end

      def available_runtime_for_required_device(required_device)
        available_runtime = available_runtime_matching_needed_runtime?(required_device.required_runtime)

        if available_runtime.nil?
          UI.important("Runtime #{required_device.required_runtime.description} not found. Skipping simulator creation for #{required_device.description}...")
          return nil
        end

        # Check if the runtime supports the device type.
        if available_runtime.supported_device_types
            .none? { |supported_device_type| supported_device_type.identifier == required_device.device_type.identifier }
          UI.important("Device type #{required_device.device_type.name} is not supported by runtime #{available_runtime.identifier}. Skipping simulator creation for #{required_device.description}...")
          return nil
        end

        if available_runtime.nil?
          UI.important("Runtime #{required_device.required_runtime.description} not found. Skipping simulator creation for #{required_device.description}...")
          return nil
        end

        available_runtime
      end

      def download_and_install_missing_runtime(missing_runtime)
        UI.message("Attempting to install #{missing_runtime.runtime_name} runtime.")

        downloaded_runtime_file = cached_runtime_file(missing_runtime)

        if downloaded_runtime_file.nil?
          shell_helper.download_runtime(missing_runtime, cache_dir)
          downloaded_runtime_file = cached_runtime_file(missing_runtime)
        end

        shell_helper.import_runtime(downloaded_runtime_file, missing_runtime.runtime_name)
      end

      def runtime_build_version_for_filename(filename)
        return nil unless filename

        # iphonesimulator_18.4_22E238.dmg
        # Format: iphonesimulator_VERSION_BUILD.dmg
        build_version = File.basename(filename, '.dmg').split('_').last

        AppleBuildVersion.new(build_version)
      end

      def cached_runtime_file(missing_runtime)
        FileUtils.mkdir_p(cache_dir)

        runtime_dmg_search_pattern = "#{cache_dir}/#{missing_runtime.sdk_platform}_#{missing_runtime.product_version}*_"

        # Remove the last character of the build version if it is the latest beta.
        # Apple can create a new Runtime version and block product build version
        # shipped with Xcode betas and use the same product version.
        # E.g. Xcode 26.0 Beta 3 has iOS 26.0 (23A5287e) SDK, but
        # xcodebuild downloads iphonesimulator_26.0_23A5287g.dmg as latest.
        runtime_dmg_search_pattern += missing_runtime.product_build_version.minor_version.to_s if missing_runtime.product_build_version
        runtime_dmg_search_pattern += '*.dmg'

        if verbose
          UI.message("Searching for #{missing_runtime.runtime_name} runtime image in #{cache_dir} with pattern: #{runtime_dmg_search_pattern}")
          UI.message("Available dmg files: #{Dir.glob("#{cache_dir}/*.dmg")}")
          UI.message("Available files with pattern: #{Dir.glob(runtime_dmg_search_pattern)}")
        end

        runtime_file = Dir
          .glob(runtime_dmg_search_pattern)
          .max_by { |filename| runtime_build_version_for_filename(filename) }

        return nil if runtime_file.nil?

        missing_runtime.product_build_version ||= runtime_build_version_for_filename(runtime_file)

        UI.message("Found existing #{missing_runtime.runtime_name} runtime image in #{cache_dir}: #{runtime_file}")

        runtime_file
      end

      def required_runtime_for_device(required_device, runtime_version)
        sdk = max_available_simulator_sdks[required_device.os_name]

        # If the runtime version is the same as the SDK version, use the SDK build version.
        # This will allow to use different runtimes for the same version but different Xcode beta versions.
        product_build_version = sdk.product_build_version if runtime_version.nil? || sdk.product_version == runtime_version

        if !runtime_version.nil? && runtime_version > sdk.product_version
          UI.important("Runtime version for #{required_device.device_type.name} (#{runtime_version}) is higher than maximum supported by the Xcode: #{sdk.product_version}")
          return nil
        end

        RequiredRuntime.new(
          sdk_platform: sdk.platform,
          os_name: required_device.os_name,
          product_version: runtime_version || sdk.product_version,
          product_build_version:,
          is_latest: sdk.product_build_version.almost_equal?(product_build_version)
        )
      end

      # Returns a hash where key is platform string and value is sdk version.
      def max_available_simulator_sdks
        return @max_available_simulator_sdks unless @max_available_simulator_sdks.nil?

        @max_available_simulator_sdks = shell_helper.available_sdks
          # Only simulators
          .filter { |sdk| sdk.platform.include?('simulator') }
          # Calculate max version for each product name
          .each_with_object({}) do |sdk, sdk_versions|
            os_name = SDK_PLATFORM_TO_OS_NAME[sdk.platform]
            stored_sdk = sdk_versions[os_name]
            sdk_versions[os_name] = sdk if stored_sdk.nil? || sdk.product_version > stored_sdk.product_version
          end

        @max_available_simulator_sdks
      end
    end
  end
end
