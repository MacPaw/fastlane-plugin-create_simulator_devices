# frozen_string_literal: true

require 'fastlane'
require 'spaceship'
require_relative '../helpers/create_simulator_devices/runner'
require_relative '../helpers/create_simulator_devices/models'
require_relative '../helpers/create_simulator_devices/models/device_naming_style'

module Fastlane
  module Actions
    CreateSimulatorDevices = ::Fastlane::CreateSimulatorDevices

    # Create simulator devices.
    class CreateSimulatorDevicesAction < Fastlane::Action
      UI = ::Fastlane::UI unless defined?(UI)

      attr_accessor :shell_helper

      def self.run(params)
        verbose = params[:verbose]
        params[:devices] = params[:devices].split(',').map(&:strip) if params[:devices].is_a?(String)
        required_devices = params[:devices]
        UI.user_error!('No devices specified') if required_devices.nil? || required_devices.empty?

        shell_helper = CreateSimulatorDevices::ShellHelper.new(print_command: params[:print_command], print_command_output: params[:print_command_output], action_context: self)
        runtime_helper = CreateSimulatorDevices::RuntimeHelper.new(cache_dir: params[:cache_dir], shell_helper: shell_helper, verbose: verbose)

        runner = CreateSimulatorDevices::Runner.new(
          runtime_helper: runtime_helper,
          shell_helper: shell_helper,
          verbose: verbose,
          can_rename_devices: params[:rename_devices],
          can_delete_duplicate_devices: params[:delete_duplicate_devices],
          device_naming_style: params[:device_naming_style].to_sym
        )

        runner.run(required_devices)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Creates simulator devices and installs missing runtimes if needed'
      end

      def self.details
        "This action does it best to create simulator devices.

        Usage sample:

        available_simulators_list = create_simulator_devices(
          devices: ['iPhone 15 (17.0)', 'iPhone 16', 'iPhone 14 (16.3)']
          verbose: false
        )"
      end

      def self.available_options # rubocop:disable Metrics/MethodLength
        [
          ::FastlaneCore::ConfigItem.new(key: :devices,
                                         env_name: 'SCAN_DEVICES',
                                         description: 'A list of simulator devices to install (e.g. "iPhone 16")',
                                         is_string: false,
                                         default_value: 'iPhone 16'),
          ::FastlaneCore::ConfigItem.new(key: :cache_dir,
                                         description: 'The directory to cache the simulator runtimes',
                                         type: String,
                                         optional: true,
                                         default_value: "#{Dir.home}/.cache/create_simulator_devices"),
          ::FastlaneCore::ConfigItem.new(key: :verbose,
                                         env_name: 'VERBOSE',
                                         description: 'Verbose output',
                                         type: Boolean,
                                         optional: true,
                                         default_value: ::FastlaneCore::Globals.verbose?,
                                         default_value_dynamic: true),
          ::FastlaneCore::ConfigItem.new(key: :print_command,
                                         description: 'Print xcrun simctl commands',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false),
          ::FastlaneCore::ConfigItem.new(key: :print_command_output,
                                         description: 'Print xcrun simctl commands output',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false),
          ::FastlaneCore::ConfigItem.new(key: :rename_devices,
                                         env_name: 'CREATE_SIMULATOR_DEVICES_RENAME_DEVICES',
                                         description: 'Rename devices if needed',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false),
          ::FastlaneCore::ConfigItem.new(key: :delete_duplicate_devices,
                                         env_name: 'CREATE_SIMULATOR_DEVICES_DELETE_DUPLICATE_DEVICES',
                                         description: 'Delete duplicate devices',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false),
          ::FastlaneCore::ConfigItem.new(key: :device_naming_style,
                                         env_name: 'CREATE_SIMULATOR_DEVICES_DEVICE_NAMING_STYLE',
                                         description: 'Device naming style',
                                         type: String,
                                         optional: true,
                                         default_value: CreateSimulatorDevices::DeviceNamingStyle::SCAN.to_s,
                                         verify_block: proc do |value|
                                           allowed_values = CreateSimulatorDevices::DeviceNamingStyle::ALL
                                           UI.user_error!("Invalid device naming style: #{value}. Allowed values: #{allowed_values.map(&:to_s).join(', ')}") unless allowed_values.include?(value.to_sym)
                                         end)
        ]
      end

      def self.output
        [
          ['AVAILABLE_SIMULATOR_DEVICES', 'A list of available simulator devices']
        ]
      end

      def self.return_value
        'Returns a list of available simulator devices'
      end

      def self.authors
        ['nekrich']
      end

      def self.is_supported?(_platform) # rubocop:disable Naming/PredicatePrefix
        true
      end
    end
  end
end
