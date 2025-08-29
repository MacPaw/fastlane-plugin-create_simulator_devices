# frozen_string_literal: true

module Fastlane
  module CreateSimulatorDevices
    class DeviceNamingStyle
      SCAN = :scan
      RUN_TESTS = :run_tests
      SNAPSHOT = :snapshot
      CAPTURE_IOS_SCREENSHOTS = :capture_ios_screenshots

      ALL = [SCAN, RUN_TESTS, SNAPSHOT, CAPTURE_IOS_SCREENSHOTS].freeze
    end
  end
end
