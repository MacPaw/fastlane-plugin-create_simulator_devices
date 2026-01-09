# frozen_string_literal: true

require_relative 'module'
require 'fastlane'
require_relative 'shared_values'
require_relative '../create_simulator_devices/models/device_naming_style'

module Fastlane
  # Gather simctl diagnose data.
  module GatherSimctlDiagnose
    # Does all the work to create simulator devices.
    class Runner
      UI = ::Fastlane::UI unless defined?(UI)

      attr_accessor :shell_helper, :verbose, :runtime_helper, :device_naming_style, :create_simulator_devices_runner, :output_dir, :timeout, :include_all_device_logs, :include_booted_device_data_directory, :print_command, :print_command_output,
                    :include_nonbooted_device_data_directory

      def initialize( # rubocop:disable Metrics/ParameterLists
        runtime_helper:,
        shell_helper:,
        verbose:,
        device_naming_style:,
        create_simulator_devices_runner:,
        output_dir:,
        timeout:,
        include_all_device_logs:,
        include_booted_device_data_directory:,
        include_nonbooted_device_data_directory:
      )
        self.shell_helper = shell_helper
        self.verbose = verbose
        self.runtime_helper = runtime_helper
        self.device_naming_style = device_naming_style
        self.create_simulator_devices_runner = create_simulator_devices_runner
        self.output_dir = output_dir
        self.timeout = timeout
        self.include_all_device_logs = include_all_device_logs
        self.include_booted_device_data_directory = include_booted_device_data_directory
        self.include_nonbooted_device_data_directory = include_nonbooted_device_data_directory
      end

      def run(devices) # rubocop:disable Metrics/AbcSize
        UI.message("Simulator devices to gather diagnose data: #{devices.join(', ')}")

        # Create distict required devices from a given list of device strings.
        required_devices = devices
          .filter_map { |device| create_simulator_devices_runner.required_device_for_device(device) }
          .uniq { |required_device| [required_device.device_type.name, required_device.required_runtime.product_version] }

        if verbose
          UI.message('Unique required devices:')
          UI.message("  #{required_devices.map(&:description).join("\n  ")}")
        end

        # Return distinct matched devices strings
        matched_simctl_devices = create_simulator_devices_runner.find_runtime_and_device_for_required_devices(required_devices)
          .reject { |required_device| required_device.simctl_device.nil? }
          .map(&:simctl_device)

        matched_devices_udids = matched_simctl_devices.map(&:udid)
        UI.message("Available simulator devices: #{matched_devices_udids.join(', ')}")

        full_output_dir_path = File.expand_path(output_dir)
        temp_output_dir = "#{full_output_dir_path}/simctl_diagnose"

        FileUtils.mkdir_p(temp_output_dir)

        diagnose_args = matched_devices_udids.map { |udid| "--udid=#{udid}" }
        diagnose_args << '-b' # Do NOT show the resulting archive in a Finder window upon completion.
        diagnose_args << '--all-logs' if include_all_device_logs
        diagnose_args << '--data-container' if include_booted_device_data_directory
        diagnose_args << "--timeout=#{timeout}"

        cmd_args = diagnose_args.map(&:shellescape).join(' ')

        collect_diagnose_data_script_path = File.expand_path("#{__dir__}/scripts/collect_simctl_diagnose_data.sh")

        UI.message("Collecting diagnose data to #{temp_output_dir}...")
        shell_helper.sh(
          command: "SIMCTL_DIAGNOSE_OUTPUT_FOLDER=#{temp_output_dir.shellescape} #{collect_diagnose_data_script_path.shellescape} #{cmd_args}",
          print_command: true,
          print_command_output: verbose
        )

        archive_name = "#{temp_output_dir}.tar.gz"
        Actions.lane_context[Actions::SharedValues::GATHER_SIMCTL_DIAGNOSE_OUTPUT_FILE] = archive_name

        copy_data_containers_and_logs(matched_simctl_devices, full_output_dir_path) if include_nonbooted_device_data_directory

        archive_name
      end

      def copy_data_containers_and_logs(matched_simctl_devices, output_dir)
        matched_simctl_devices
          .reject { |simctl_device| simctl_device.state == 'Booted' }
          .each { |simctl_device| copy_data_container_and_logs(simctl_device, output_dir) }
      end

      def copy_data_container_and_logs(simctl_device, output_dir)
        if File.exist?(simctl_device.data_path)
          UI.message("Copying data from #{simctl_device.data_path} to #{output_dir}...")
          shell_helper.sh(
            command: "tar -czf #{output_dir}/#{simctl_device.name.shellescape}_#{simctl_device.udid.shellescape}_data.tar.gz --cd #{File.dirname(simctl_device.data_path).shellescape} #{File.basename(simctl_device.data_path).shellescape}"
          )
        end

        return unless File.exist?(simctl_device.log_path)

        UI.message("Copying logs from #{simctl_device.log_path} to #{output_dir}...")
        shell_helper.sh(
          command: "tar -czf #{output_dir}/#{simctl_device.name.shellescape}_#{simctl_device.udid.shellescape}_logs.tar.gz --cd #{File.dirname(simctl_device.log_path).shellescape} #{File.basename(simctl_device.log_path).shellescape}"
        )
      end
    end
  end
end
