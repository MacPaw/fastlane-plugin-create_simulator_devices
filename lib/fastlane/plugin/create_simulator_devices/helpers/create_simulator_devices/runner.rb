# frozen_string_literal: true

require_relative 'runtime_helper'

module Fastlane
  # Create simulator devices.
  module CreateSimulatorDevices
    # Does all the work to create simulator devices.
    class Runner
      UI = ::Fastlane::UI unless defined?(UI)

      attr_accessor :shell_helper, :verbose, :runtime_helper

      def initialize(runtime_helper:, shell_helper:, verbose:)
        self.shell_helper = shell_helper
        self.verbose = verbose || shell_helper.verbose
        self.runtime_helper = runtime_helper
      end

      def run(devices)
        shell_helper.stop_core_simulator_services

        # Delete unusable runtimes and unavailable devices.
        runtime_helper.delete_unusable_runtimes
        delete_unavailable_devices

        # Create distict required devices from a given list of device strings.
        required_devices = devices
          .filter_map { |device| required_device_for_device(device) }
          .uniq { |required_device| [required_device.device_type.name, required_device.required_runtime.product_version] }

        # Install missing runtimes if needed.
        runtime_helper.install_missing_runtimes(required_devices)

        # Create missing devices for required devices.
        create_missing_devices(required_devices)

        # Return distinct matched devices strings
        matched_devices = required_devices
          .reject { |required_device| required_device.available_device.nil? }

        if verbose
          UI.message('Matched devices:')
          matched_devices.each do |matched_device|
            UI.message("\n\t#{matched_device.description}: #{matched_device.available_device.description}")
          end
        end

        matched_devices.map!(&:description)

        UI.user_error!('No available devices found') if matched_devices.empty?

        matched_devices
      end

      def delete_unavailable_devices
        return unless shell_helper.available_devices_for_runtimes.values.flatten.any?(&:available?)

        shell_helper.delete_unavailable_devices

        shell_helper.available_devices_for_runtimes(force: true)
      end

      def available_device_for_required_device(required_device)
        return nil if required_device.available_runtime.nil?

        available_devices = shell_helper.available_devices_for_runtimes[required_device.available_runtime.identifier.to_sym]

        return [] if available_devices.nil?

        available_devices.detect { |device| device.device_type_identifier == required_device.device_type.identifier }
      end

      def create_missing_devices(required_devices)
        find_runtime_and_device_for_required_devices(required_devices)

        missing_devices = required_devices
          .select { |required_device| required_device.available_device.nil? }

        return if missing_devices.empty?

        UI.message('Creating missing devices')
        missing_devices.each do |missing_device|
          shell_helper.create_device(
            missing_device.description,
            missing_device.device_type.identifier,
            missing_device.available_runtime.identifier
          )
        end

        shell_helper.available_devices_for_runtimes(force: true)

        find_runtime_and_device_for_required_devices(missing_devices)
      end

      def find_runtime_and_device_for_required_devices(required_devices)
        UI.message('Searching for matching available devices...')
        required_devices.each do |required_device|
          required_device.available_runtime = runtime_helper.available_runtime_for_required_device(required_device)
          required_device.available_device = available_device_for_required_device(required_device)
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
        available_device_types = shell_helper.available_device_types

        device_type = available_device_types.detect do |available_device_type|
          # Avoid matching "iPhone 16" for the "iPhone 16e" device.
          "#{device} ".start_with?("#{available_device_type.name} ")
        end

        unless device_type
          UI.important("Device type not found for device #{device}")
          return nil
        end

        product_family = device_type.product_family

        os_name = PRODUCT_FAMILY_TO_OS_NAME[product_family]
        device_os_version = device.delete_prefix(device_type.name).strip
        device_os_version = device_os_version[/\(([\d.]*?)\)/, 1]

        runtime_version = nil
        unless device_os_version.nil? || device_os_version.empty?
          device_os_version += '.0' if device_os_version.scan('.').none?

          runtime_version = Gem::Version.new(device_os_version)
        end

        required_device = RequiredDevice.new(
          device_type:,
          os_name:,
          required_runtime: nil,
          available_runtime: nil,
          available_device: nil
        )

        required_device.required_runtime = runtime_helper.required_runtime_for_device(required_device, runtime_version)

        required_device.required_runtime.nil? ? nil : required_device
      end
    end
  end
end
