# frozen_string_literal: true

require_relative 'models'
require 'fastlane'

module Fastlane
  # Create simulator devices.
  module CreateSimulatorDevices
    # Shell helper
    class ShellHelper
      UI = ::Fastlane::UI unless defined?(UI)

      # Proprty verbose
      attr_accessor :verbose, :print_command, :print_command_output, :action_context

      def initialize(verbose: false, print_command: false, print_command_output: false, action_context: nil)
        self.verbose = verbose
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

      def simctl_device_types(force: false)
        return @simctl_device_types unless force || @simctl_device_types.nil?

        UI.message('Fetching available device types...')
        json = sh(command: 'xcrun simctl list --json --no-escape-slashes devicetypes')

        @simctl_device_types = JSON
          .parse(json, symbolize_names: true)[:devicetypes]
          .map { |device_type| SimCTL::DeviceType.from_hash(device_type) }

        @simctl_device_types
      end

      def delete_device(udid:)
        UI.message("Deleting device #{udid}...")
        sh(command: "xcrun simctl delete #{udid.shellescape}")
      end

      def delete_unavailable_devices
        UI.message('Deleting unavailable devices...')
        sh(command: 'xcrun simctl delete unavailable')
      end

      def simctl_devices_for_runtimes(force: false)
        return @simctl_devices_for_runtimes unless force || @simctl_devices_for_runtimes.nil?

        UI.message('Fetching available devices...')
        json = sh(command: 'xcrun simctl list --json --no-escape-slashes devices')

        @simctl_devices_for_runtimes = JSON
          .parse(json, symbolize_names: true)[:devices]
          .transform_values { |devices| devices.map { |device| SimCTL::Device.from_hash(device) } }

        @simctl_devices_for_runtimes
      end

      def simctl_runtimes(force: false)
        return @simctl_runtimes unless force || @simctl_runtimes.nil?

        UI.message('Fetching available runtimes...')
        json = sh(command: 'xcrun simctl list --json --no-escape-slashes runtimes')

        @simctl_runtimes = JSON
          .parse(json, symbolize_names: true)[:runtimes]
          .map { |runtime| SimCTL::Runtime.from_hash(runtime) }
          .select(&:available?)

        @simctl_runtimes
      end

      def simctl_delete_runtime(identifier:)
        UI.message("Deleting runtime #{identifier}...")
        sh(command: "xcrun simctl runtime delete #{identifier.shellescape}")
      end

      def simctl_matched_runtimes(force: false)
        return @simctl_matched_runtimes unless force || @simctl_matched_runtimes.nil?

        UI.message('Fetching matched runtimes...')
        json = sh(command: 'xcrun simctl runtime match list --json')

        @simctl_matched_runtimes = JSON
          .parse(json, symbolize_names: true)
          .map { |identifier, runtime| SimCTL::MatchedRuntime.from_hash(runtime, identifier: identifier) }
      end

      def installed_runtimes_with_state
        UI.message('Fetching runtimes with state...')
        json = sh(command: 'xcrun simctl runtime list --json')

        JSON
          .parse(json, symbolize_names: true)
          .map { |_, runtime| SimCTL::RuntimeWithState.from_hash(runtime) }
      end

      def xcodebuild_sdks(force: false)
        return @xcodebuild_sdks unless force || @xcodebuild_sdks.nil?

        UI.message('Fetching available sdks...')
        json = sh(command: 'xcrun xcodebuild -showsdks -json')

        @xcodebuild_sdks = JSON
          .parse(json, symbolize_names: true)
          .map { |sdk| Xcodebuild::SDK.from_hash(sdk) }

        @xcodebuild_sdks
      end

      def create_device(name, device_type_identifier, runtime_identifier)
        UI.message("Creating device #{name}")
        sh(command: "xcrun simctl create #{name.shellescape} #{device_type_identifier.shellescape} #{runtime_identifier.shellescape}")
      end

      def rename_device(udid:, name:)
        UI.message("Renaming device with udid #{udid} to #{name}")
        sh(command: "xcrun simctl rename #{udid.shellescape} #{name.shellescape}")
      end

      def delete_runtime(runtime_identifier)
        UI.message("Deleting runtime #{runtime_identifier}...")
        sh(command: "xcrun simctl runtime delete #{runtime_identifier.shellescape}")
      end

      def download_runtime(missing_runtime, cache_dir)
        command = [
          'xcrun',
          'xcodebuild',
          '-verbose',

          '-exportPath',
          cache_dir.shellescape,

          '-downloadPlatform',
          missing_runtime.os_name.shellescape
        ]

        is_beta = missing_runtime.product_build_version.nil? ? false : missing_runtime.product_build_version.beta?

        unless is_beta
          command << '-buildVersion'
          command << missing_runtime.product_version.to_s.shellescape
        end

        simulator_architecture_variant = 'universal'

        if Fastlane::Helper.xcode_at_least?('26') && missing_runtime.product_version >= '26'
          xcode_binary_path = File.join(Fastlane::Helper.xcode_path, '..', 'MacOS', 'Xcode')
          xcode_binary_path = File.expand_path(xcode_binary_path)

          UI.message('Getting Xcode architecture variants with lipo...') if verbose

          xcode_architecture_variants = sh(command: "lipo -archs #{xcode_binary_path.shellescape}", print_command: print_command, print_command_output: print_command_output).split

          UI.message("Xcode architecture variants: #{xcode_architecture_variants}") if verbose

          simulator_architecture_variant = if xcode_architecture_variants.include?('x86_64')
                                             'universal'
                                           else
                                             'arm64'
                                           end

          command << '-architectureVariant'
          command << simulator_architecture_variant.shellescape
        end

        UI.message("Downloading #{missing_runtime.runtime_name} (arch: #{simulator_architecture_variant}) to #{cache_dir}. This may take a while...")

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

      def update_dyld_shared_cache
        sh(
          command: 'xcrun simctl runtime dyld_shared_cache update --all'
        )
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
