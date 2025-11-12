# frozen_string_literal: true

require 'fastlane'
require 'spaceship'
require_relative '../helpers/create_simulator_devices/shell_helper'
require_relative '../helpers/create_simulator_devices/runner'
require_relative '../helpers/create_simulator_devices/models/device_naming_style'
require_relative '../helpers/gather_simctl_diagnose/runner'

module Fastlane
  module Actions
    GatherSimctlDiagnose = ::Fastlane::GatherSimctlDiagnose
    CreateSimulatorDevices = ::Fastlane::CreateSimulatorDevices

    # Gather simctl diagnose data.
    class GatherSimctlDiagnoseAction < Fastlane::Action
      UI = ::Fastlane::UI unless defined?(UI)

      attr_accessor :shell_helper

      def self.run(params)
        verbose = params[:verbose]
        params[:devices] = params[:devices].split(',').map(&:strip) if params[:devices].is_a?(String)
        required_devices = params[:devices]
        UI.user_error!('No devices specified') if required_devices.nil? || required_devices.empty?

        shell_helper = CreateSimulatorDevices::ShellHelper.new(verbose: verbose, print_command: params[:print_command], print_command_output: params[:print_command_output], action_context: self)
        runtime_helper = CreateSimulatorDevices::RuntimeHelper.new(cache_dir: nil, shell_helper: shell_helper, verbose: verbose)

        create_simulator_devices_runner = ::Fastlane::CreateSimulatorDevices::Runner.new(
          runtime_helper: runtime_helper,
          shell_helper: shell_helper,
          verbose: verbose,
          can_rename_devices: false,
          can_delete_duplicate_devices: false,
          device_naming_style: params[:device_naming_style].to_sym,
          remove_cached_runtimes: false
        )

        runner = GatherSimctlDiagnose::Runner.new(
          runtime_helper: runtime_helper,
          shell_helper: shell_helper,
          verbose: verbose,
          device_naming_style: params[:device_naming_style].to_sym,
          create_simulator_devices_runner: create_simulator_devices_runner,
          output_dir: params[:output_dir],
          timeout: params[:timeout],
          include_all_device_logs: params[:include_all_device_logs],
          include_booted_device_data_directory: params[:include_booted_device_data_directory],
          include_nonbooted_device_data_directory: params[:include_nonbooted_device_data_directory]
        )

        runner.run(required_devices)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gathers simctl diagnose data'
      end

      def self.details
        "This action gathers simctl diagnose data.

        Usage sample:

        gather_simctl_diagnose(
          devices: ['iPhone 15 (17.0)', 'iPhone 16', 'iPhone 14 (16.3)']
          output_dir: 'diagnose'
        )"
      end

      def self.available_options # rubocop:disable Metrics/MethodLength
        [
          ::FastlaneCore::ConfigItem.new(key: :devices,
                                         env_name: 'SCAN_DEVICES',
                                         description: 'A list of simulator devices to install (e.g. "iPhone 16")',
                                         is_string: false,
                                         default_value: 'iPhone 16'),
          ::FastlaneCore::ConfigItem.new(key: :verbose,
                                         env_name: 'VERBOSE',
                                         description: 'Verbose output',
                                         type: Boolean,
                                         optional: true,
                                         default_value: ::FastlaneCore::Globals.verbose?,
                                         default_value_dynamic: true),
          ::FastlaneCore::ConfigItem.new(key: :output_dir,
                                         env_name: 'GATHER_SIMCTL_DIAGNOSE_OUTPUT_DIR',
                                         description: 'Output directory',
                                         type: String,
                                         optional: false),
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
          ::FastlaneCore::ConfigItem.new(key: :device_naming_style,
                                         env_name: 'CREATE_SIMULATOR_DEVICES_DEVICE_NAMING_STYLE',
                                         description: 'Device naming style',
                                         type: String,
                                         optional: true,
                                         default_value: CreateSimulatorDevices::DeviceNamingStyle::SCAN.to_s,
                                         verify_block: proc do |value|
                                           allowed_values = CreateSimulatorDevices::DeviceNamingStyle::ALL
                                           UI.user_error!("Invalid device naming style: #{value}. Allowed values: #{allowed_values.map(&:to_s).join(', ')}") unless allowed_values.include?(value.to_sym)
                                         end),
          ::FastlaneCore::ConfigItem.new(key: :timeout,
                                         env_name: 'GATHER_SIMCTL_DIAGNOSE_TIMEOUT',
                                         description: 'Timeout',
                                         type: Integer,
                                         optional: true,
                                         default_value: 300),
          ::FastlaneCore::ConfigItem.new(key: :include_all_device_logs,
                                         env_name: 'GATHER_SIMCTL_DIAGNOSE_INCLUDE_ALL_DEVICE_LOGS',
                                         description: 'Include all device logs',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false),
          ::FastlaneCore::ConfigItem.new(key: :include_booted_device_data_directory,
                                         env_name: 'GATHER_SIMCTL_DIAGNOSE_INCLUDE_BOOTED_DEVICE_DATA_DIRECTORY',
                                         description: 'Include booted device data directory. Warning: May include private information, app data containers, and increases the size of the archive! Default is NOT to collect the data container',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false),
          ::FastlaneCore::ConfigItem.new(key: :include_nonbooted_device_data_directory,
                                         env_name: 'GATHER_SIMCTL_DIAGNOSE_INCLUDE_NONBOOTED_DEVICE_DATA_DIRECTORY',
                                         description: 'Include non-booted device data directory. Warning: May include private information, app data containers, and increases the size of the archive! Default is NOT to collect the data container',
                                         type: Boolean,
                                         optional: true,
                                         default_value: false)
        ]
      end

      def self.output
        [
          ['GATHER_SIMCTL_DIAGNOSE_OUTPUT_FILE', 'Output archive file with simctl diagnose data']
        ]
      end

      def self.return_value
        'Returns a path to the output archive file with simctl diagnose data'
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
