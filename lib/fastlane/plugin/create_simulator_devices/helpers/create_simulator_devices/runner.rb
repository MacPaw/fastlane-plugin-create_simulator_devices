# frozen_string_literal: true

require_relative 'runtime_helper'
require 'fastlane'
require_relative 'shared_values'
require_relative 'models/device_naming_style'

module Fastlane
  # Create simulator devices.
  module CreateSimulatorDevices
    # Does all the work to create simulator devices.
    class Runner # rubocop:disable Metrics/ClassLength
      UI = ::Fastlane::UI unless defined?(UI)

      attr_accessor :shell_helper, :verbose, :runtime_helper, :can_rename_devices, :can_delete_duplicate_devices, :device_naming_style

      def initialize(runtime_helper:, shell_helper:, verbose:, can_rename_devices:, can_delete_duplicate_devices:, device_naming_style:) # rubocop:disable Metrics/ParameterLists
        self.shell_helper = shell_helper
        self.verbose = verbose
        self.runtime_helper = runtime_helper
        self.can_rename_devices = can_rename_devices
        self.can_delete_duplicate_devices = can_delete_duplicate_devices
        self.device_naming_style = device_naming_style
      end

      def run(devices)
        UI.message("Simulator devices to create: #{devices.join(', ')}")

        shell_helper.stop_core_simulator_services

        # Delete unusable runtimes and unavailable devices.
        runtime_helper.delete_unusable_runtimes
        delete_unavailable_devices

        # Create distict required devices from a given list of device strings.
        required_devices = devices
          .filter_map { |device| required_device_for_device(device) }
          .uniq { |required_device| [required_device.device_type.name, required_device.required_runtime.product_version] }

        if verbose
          UI.message('Unique required devices:')
          UI.message("  #{required_devices.map(&:description).join("\n  ")}")
        end

        # Install missing runtimes if needed.
        runtime_helper.install_missing_runtimes(required_devices)

        # Create missing devices for required devices.
        create_missing_devices(required_devices)

        # Return distinct matched devices strings
        matched_devices = required_devices
          .reject { |required_device| required_device.simctl_device.nil? }

        log_matched_devices(matched_devices: matched_devices)

        matched_devices_names = matched_devices.map { |matched_device| returning_device_name_for_required_device(matched_device) }
        UI.message("Available simulator devices: #{matched_devices_names.join(', ')}")

        Actions.lane_context[Actions::SharedValues::AVAILABLE_SIMULATOR_DEVICES] = matched_devices_names

        matched_devices_names
      end

      def log_matched_devices(matched_devices:)
        UI.user_error!('No available devices found') if matched_devices.empty?

        UI.message('Matched devices:')
        matched_devices.each do |matched_device|
          device_info = ''
          if verbose
            device_info = shell_helper.device_info_by_udid(matched_device.simctl_device.udid)
            device_info = "\n#{device_info}"
          end
          UI.message("  #{matched_device.description}: #{matched_device.simctl_device.description}#{device_info}")
        end
      end

      def delete_unavailable_devices
        return unless shell_helper.simctl_devices_for_runtimes.values.flatten.any?(&:available?)

        shell_helper.delete_unavailable_devices

        shell_helper.simctl_devices_for_runtimes(force: true)
      end

      def simctl_device_for_required_device(required_device)
        return nil if required_device.simctl_runtime.nil?

        simctl_devices = shell_helper.simctl_devices_for_runtimes[required_device.simctl_runtime.identifier.to_sym]

        return nil if simctl_devices.nil?

        # Find the device with the same name as the required device.
        devices_with_same_type = simctl_devices
          .select { |simctl_device| simctl_device.device_type_identifier == required_device.device_type.identifier }

        preferred_device_name = device_name_for_required_device(required_device)

        # Prefer device with the same name that includes the runtime version.
        matching_device = devices_with_same_type.detect { |simctl_device| simctl_device.name == preferred_device_name }

        if can_rename_devices
          # Otherwise, if rename is enabled, use the first device with the same type.
          matching_device ||= devices_with_same_type.first
          rename_device_if_needed(matching_device, preferred_device_name)
        end

        delete_duplicate_devices(devices_with_same_type, matching_device) if can_delete_duplicate_devices

        matching_device
      end

      def rename_device_if_needed(matching_device, preferred_device_name)
        return if matching_device.nil? || matching_device.name == preferred_device_name

        UI.message("Renaming device #{matching_device.name} (udid: #{matching_device.udid}) to #{preferred_device_name}")
        shell_helper.rename_device(udid: matching_device.udid, name: preferred_device_name)
        matching_device.name = preferred_device_name
      end

      def delete_duplicate_devices(matching_devices, matching_device)
        return if matching_device.nil?

        matching_devices
          .reject { |simctl_device| simctl_device.udid == matching_device.udid }
          .each do |simctl_device|
            UI.message("Deleting duplicate device #{simctl_device.name} (udid: #{simctl_device.udid})")
            shell_helper.delete_device(udid: simctl_device.udid)
          end
      end

      # Returns the device name for the required device.
      #
      # This name is used in the simctl device name.
      def device_name_for_required_device(required_device)
        case device_naming_style
        when DeviceNamingStyle::SCAN, DeviceNamingStyle::RUN_TESTS
          # scan modifies the device name by removing the runtime version when searching for a passed device name.
          # E.g.:
          #   * given "iPhone 15 (17.0)" match will search for simulator named "iPhone 15" with the SDK version 17.0.
          #   * given "iPhone 15" match will search for simulator named "iPhone 15" with the default SDK version.
          # So we need to name the device by the device type name for scan to find the correct device.
          required_device.device_type.name
        when DeviceNamingStyle::SNAPSHOT, DeviceNamingStyle::CAPTURE_IOS_SCREENSHOTS
          # snapshot nither does not modify the device name when searching for a passed device name nor extracts the runtime version from the device name.
          # E.g.:
          #   * given "iPhone 15 (17.0)" match will search for device named exactly "iPhone 15 (17.0)".
          #   * given "iPhone 15" match will search for device named exactly "iPhone 15".
          # So we need to return the full device name for the required device for snapshot to find the correct device.
          "#{required_device.device_type.name} (#{required_device.required_runtime.product_version})"
        end
      end

      # Returns the device name for the required device.
      #
      # This name is used when passing the device name to the scan or snapshot.
      def returning_device_name_for_required_device(required_device)
        case device_naming_style
        when DeviceNamingStyle::SCAN, DeviceNamingStyle::RUN_TESTS
          # scan respects the runtime version in the devices list, so we need to return the full device name for the required device, otherwise the default SDK version will be used.
          # E.g.:
          #   * given "iPhone 15 (17.0)" match will search for simulator named "iPhone 15" with the SDK version 17.0.
          #   * given "iPhone 15" match will search for simulator named "iPhone 15" with the default SDK version.
          # So we need to return the device name and the required runtime version for scan to find the correct device.
          "#{required_device.simctl_device.name} (#{required_device.required_runtime.product_version})"
        when DeviceNamingStyle::SNAPSHOT, DeviceNamingStyle::CAPTURE_IOS_SCREENSHOTS
          # snapshot does not modify the device name when searching for a passed device name nor extracts the runtime version from the device name.
          # E.g.:
          #   * given "iPhone 15 (17.0)" match will search for device named exactly "iPhone 15 (17.0)".
          #   * given "iPhone 15" match will search for device named exactly "iPhone 15" .
          # So we need to return the full device name for the required device for snapshot to find the correct device.
          required_device.simctl_device.name
        end
      end

      def create_missing_devices(required_devices)
        find_runtime_and_device_for_required_devices(required_devices)

        missing_devices = required_devices
          .select { |required_device| required_device.simctl_device.nil? }

        if missing_devices.empty?
          UI.message('All required devices are present. Skipping device creation...') if verbose
          return
        end

        UI.message('Creating missing devices')
        missing_devices.each do |missing_device|
          shell_helper.create_device(
            device_name_for_required_device(missing_device),
            missing_device.device_type.identifier,
            missing_device.simctl_runtime.identifier
          )
        end

        shell_helper.simctl_devices_for_runtimes(force: true)

        find_runtime_and_device_for_required_devices(missing_devices)
      end

      def find_runtime_and_device_for_required_devices(required_devices)
        UI.message('Searching for matching available devices...')
        required_devices.each do |required_device|
          required_device.simctl_runtime = runtime_helper.simctl_runtime_for_required_device(required_device)
          required_device.simctl_device = simctl_device_for_required_device(required_device)
        end
      end

      PRODUCT_FAMILY_TO_OS_NAME = {
        'iPhone' => 'iOS',
        'iPad' => 'iOS',
        'iPod' => 'iOS',
        'Apple TV' => 'tvOS',
        'Apple Watch' => 'watchOS',
        'Apple Vision' => 'xrOS'
      }.freeze

      def required_device_for_device(device)
        simctl_device_types = shell_helper.simctl_device_types

        device_os_version = device[/ \(([\d.]*?)\)$/, 1]
        device_name = device_os_version.nil? ? device : device.delete_suffix(" (#{device_os_version})").strip

        device_type = simctl_device_types.detect do |simctl_device_type|
          device_name == simctl_device_type.name
        end

        unless device_type
          UI.important("Device type not found for device #{device}. Available device types: #{simctl_device_types.map(&:name).join(', ')}.")
          return nil
        end

        product_family = device_type.product_family

        os_name = PRODUCT_FAMILY_TO_OS_NAME[product_family]

        runtime_version = nil
        unless device_os_version.nil? || device_os_version.empty?
          device_os_version += '.0' if device_os_version.scan('.').none?

          runtime_version = Gem::Version.new(device_os_version)
        end

        required_device = RequiredDevice.new(
          device_type:,
          os_name:,
          required_runtime: nil,
          simctl_runtime: nil,
          simctl_device: nil
        )

        required_device.required_runtime = runtime_helper.required_runtime_for_device(required_device, runtime_version)

        required_device.required_runtime.nil? ? nil : required_device
      end
    end
  end
end
