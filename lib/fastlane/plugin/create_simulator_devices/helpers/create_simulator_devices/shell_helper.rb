# frozen_string_literal: true

require_relative 'models'

module Fastlane
  # Create simulator devices.
  module CreateSimulatorDevices
    # Shell helper
    class ShellHelper
      UI = ::Fastlane::UI unless defined?(UI)

      # Proprty verbose
      attr_accessor :print_command, :print_command_output, :action_context

      def initialize(print_command: false, print_command_output: false, action_context: nil)
        self.print_command = print_command
        self.print_command_output = print_command_output
        self.action_context = action_context
      end

      def sh(command:, print_command: self.print_command, print_command_output: self.print_command_output)
        if action_context
          action_context.sh(command, print_command: print_command, print_command_output: print_command_output)
        else
          # Fallback for testing or direct usage
          require 'open3'
          stdout, stderr, status = Open3.capture3(command)

          UI.message command if print_command

          if status.success?
            UI.message stdout if print_command_output
            stdout
          else
            error_message = "Command failed: #{command}\n#{stderr}"
            UI.error error_message
            raise StandardError, error_message
          end
        end
      end

      def stop_core_simulator_services
        UI.message('Stop CoreSimulator')
        services_to_stop = [
          'com.apple.CoreSimulator.CoreSimulatorService',
          'com.apple.CoreSimulator.SimulatorTrampoline',
          'com.apple.CoreSimulator.SimLaunchHost-arm64',
          'com.apple.CoreSimulator.SimLaunchHost-x86'
        ]
        services_to_stop.each do |service|
          sh(command: "launchctl remove #{service} || true")
        end
      end

      def available_device_types(force: false)
        return @available_device_types unless force || @available_device_types.nil?

        UI.message('Fetching available device types...')
        json = sh(command: 'xcrun simctl list --json --no-escape-slashes devicetypes')

        @available_device_types = JSON
          .parse(json, symbolize_names: true)[:devicetypes]
          .map { |device_type| SimCTL::DeviceType.from_hash(device_type) }

        @available_device_types
      end

      def delete_device(udid)
        UI.message("Deleting device #{udid}...")
        sh(command: "xcrun simctl delete #{udid.shellescape}")
      end

      def delete_unavailable_devices
        UI.message('Deleting unavailable devices...')
        sh(command: 'xcrun simctl delete unavailable')
      end

      def available_devices_for_runtimes(force: false)
        return @available_devices_for_runtimes unless force || @available_devices_for_runtimes.nil?

        UI.message('Fetching available devices...')
        json = sh(command: 'xcrun simctl list --json --no-escape-slashes devices')

        @available_devices_for_runtimes = JSON
          .parse(json, symbolize_names: true)[:devices]
          .transform_values { |devices| devices.map { |device| SimCTL::Device.from_hash(device) } }

        @available_devices_for_runtimes
      end

      def available_runtimes(force: false)
        return @available_runtimes unless force || @available_runtimes.nil?

        UI.message('Fetching available runtimes...')
        json = sh(command: 'xcrun simctl list --json --no-escape-slashes runtimes')

        @available_runtimes = JSON
          .parse(json, symbolize_names: true)[:runtimes]
          .map { |runtime| SimCTL::Runtime.from_hash(runtime) }
          .select(&:available?)

        @available_runtimes
      end

      def installed_runtimes_with_state
        UI.message('Fetching runtimes with state...')
        json = sh(command: 'xcrun simctl runtime list --json')

        JSON
          .parse(json, symbolize_names: true)
          .map { |_, runtime| SimCTL::RuntimeWithState.from_hash(runtime) }
      end

      def available_sdks(force: false)
        return @available_sdks unless force || @available_sdks.nil?

        UI.message('Fetching available sdks...')
        json = sh(command: 'xcrun xcodebuild -showsdks -json')

        @available_sdks = JSON
          .parse(json, symbolize_names: true)
          .map { |sdk| Xcodebuild::SDK.from_hash(sdk) }

        @available_sdks
      end

      def create_device(name, device_type_identifier, runtime_identifier)
        UI.message("Creating device #{name}")
        sh(command: "xcrun simctl create #{name.shellescape} #{device_type_identifier.shellescape} #{runtime_identifier.shellescape}")
      end

      def delete_runtime(runtime_identifier)
        UI.message("Deleting runtime #{runtime_identifier}...")
        sh(command: "xcrun simctl runtime delete #{runtime_identifier.shellescape}")
      end

      def download_runtime(missing_runtime, cache_dir)
        UI.message("Downloading #{missing_runtime.runtime_name} to #{cache_dir}. This may take a while...")

        command = [
          'xcrun',
          'xcodebuild',
          '-verbose',

          '-exportPath',
          cache_dir.shellescape,

          '-downloadPlatform',
          missing_runtime.os_name.shellescape
        ]

        command << '-buildVersion'
        command << missing_runtime.product_version.to_s.shellescape

        sh(command: command.join(' '), print_command: true, print_command_output: true)
      end

      def import_runtime(runtime_dmg_filename, runtime_name)
        UI.message("Importing runtime #{runtime_name} image from #{runtime_dmg_filename}...")
        import_platform_command = "xcrun xcodebuild -verbose -importPlatform #{runtime_dmg_filename.shellescape}"
        begin
          sh(command: import_platform_command)
        rescue StandardError => e
          UI.important("Failed to import runtime #{runtime_name} with '#{import_platform_command}' :\n#{e}")
        end
      end

      def device_info_by_udid(udid)
        sh(
          command: "xcrun simctl list devices --json | jq '.devices | to_entries[].value[] | select(.udid==\"#{udid.shellescape}\")'",
          print_command: false,
          print_command_output: false
        )
      end
    end
  end
end
