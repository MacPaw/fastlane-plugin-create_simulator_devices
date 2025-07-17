# frozen_string_literal: true

module Fastlane
  module CreateSimulatorDevices
    # Represents a required runtime.
    class RequiredRuntime
      attr_accessor :sdk_platform, :os_name, :product_version, :product_build_version, :is_latest

      def initialize(sdk_platform:, os_name:, product_version:, product_build_version:, is_latest: false)
        self.sdk_platform = sdk_platform
        self.os_name = os_name
        self.product_version = product_version
        self.product_build_version = product_build_version
        self.is_latest = is_latest
      end

      def runtime_name
        [os_name, product_version].compact.join(' ')
      end

      def latest?
        is_latest
      end

      def beta?
        return false unless product_build_version

        product_build_version.beta?
      end

      def eql?(other)
        other.sdk_platform == sdk_platform && other.os_name == os_name && other.product_version == product_version && other.product_build_version == product_build_version
      end

      def hash
        [sdk_platform, os_name, product_version, product_build_version].compact.hash
      end

      def description
        "#{os_name} (#{product_version}, #{product_build_version})"
      end
    end
  end
end
