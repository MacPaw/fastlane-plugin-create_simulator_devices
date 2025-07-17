# frozen_string_literal: true

module Fastlane
  module CreateSimulatorDevices
    # Represents a required runtime.
    class RequiredDevice
      attr_accessor :device_type, :os_name, :required_runtime, :available_runtime, :available_device

      def initialize(device_type:, os_name:, required_runtime:, available_runtime:, available_device:)
        self.device_type = device_type
        self.os_name = os_name
        self.required_runtime = required_runtime
        self.available_runtime = available_runtime
        self.available_device = available_device
      end

      def description
        if required_runtime
          "#{device_type.name} (#{required_runtime.product_version})"
        else
          device_type.name
        end
      end
    end
  end
end
