# frozen_string_literal: true

require 'fastlane'
require 'spaceship'
require_relative '../helpers/create_simulator_devices/runner'
require_relative '../helpers/create_simulator_devices/models'

module Fastlane
  module Actions
    module SharedValues
      AVAILABLE_SIMULATOR_DEVICES = :AVAILABLE_SIMULATOR_DEVICES
    end

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

        shell_helper = CreateSimulatorDevices::ShellHelper.new(verbose:, action_context: self)
        runtime_helper = CreateSimulatorDevices::RuntimeHelper.new(cache_dir: params[:cache_dir], shell_helper:, verbose:)

        runner = CreateSimulatorDevices::Runner.new(
          runtime_helper: runtime_helper,
          shell_helper: shell_helper,
          verbose: verbose
        )

        available_simulator_devices = runner.run(required_devices)

        Actions.lane_context[SharedValues::AVAILABLE_SIMULATOR_DEVICES] = available_simulator_devices

        available_simulator_devices
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

      def self.available_options
        [
          ::FastlaneCore::ConfigItem.new(key: :devices,
                                         env_name: 'SCAN_DEVICES',
                                         description: 'A list of simulator devices to install (e.g. "iPhone 16")',
                                         is_string: false,
                                         default_value: 'iPhone 16'),
          ::FastlaneCore::ConfigItem.new(key: :cache_dir,
                                         description: 'The directory to cache the simulator runtimes',
                                         is_string: true,
                                         optional: true,
                                         default_value: "#{Dir.home}/.cache/create_simulator_devices"),
          ::FastlaneCore::ConfigItem.new(key: :verbose,
                                         env_name: 'VERBOSE',
                                         description: 'Verbose output',
                                         is_string: false,
                                         optional: true,
                                         default_value: ::FastlaneCore::Globals.verbose?,
                                         default_value_dynamic: true)
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
