# frozen_string_literal: true

module Fastlane
  # Create simulator devices.
  module CreateSimulatorDevices
    # Compare model for Apple build versions.
    class AppleBuildVersion
      def initialize(build_version)
        return if build_version.nil? || build_version.empty?

        @build_version = build_version
      end

      def beta?
        @build_version.length >= 8
      end

      def <=>(other)
        lhs_build_version = @build_version
        rhs_build_version = other.to_s

        return 0 if lhs_build_version == rhs_build_version

        lhs_sdk_version = lhs_build_version[0...3]
        rhs_sdk_version = rhs_build_version[0...3]

        # Check if the SDK major.minor versions (first 3 characters) are the same.
        # If they are the same, compare only SDK versions.
        return lhs_sdk_version <=> rhs_sdk_version if lhs_sdk_version != rhs_sdk_version

        lhs_is_beta = beta?
        # In case we compare with a string, convert it to the AppleBuildVersion object.
        rhs_is_beta = AppleBuildVersion.new(rhs_build_version).beta?

        return lhs_is_beta ? -1 : 1 if lhs_is_beta != rhs_is_beta

        # If the build versions are the same length, compare them lexicographically.
        # Otherwise, compare the length of the build versions.
        if lhs_build_version.length == rhs_build_version.length
          lhs_build_version <=> rhs_build_version
        else
          # iOS 16.0 Release: 22A3362
          # iOS 16.0 RC1: 22A348
          # Trying to compare them lexicographically will return false ("22A3362" < "22A348").
          # So we need to compare the length of the build versions.
          lhs_build_version.length <=> rhs_build_version.length
        end
      end

      def almost_equal?(other)
        return false if other.nil?

        lhs_build_version = @build_version
        rhs_build_version = other.to_s

        lhs_is_beta = beta?
        rhs_is_beta = AppleBuildVersion.new(rhs_build_version).beta?

        return self == other unless lhs_is_beta && rhs_is_beta && lhs_build_version.length == rhs_build_version.length

        lhs_build_version.chop == rhs_build_version.chop
      end

      def <(other)
        (self <=> other).negative?
      end

      def >(other)
        (self <=> other).positive?
      end

      def <=(other)
        !(self <=> other).positive?
      end

      def >=(other)
        !(self <=> other).negative?
      end

      def eql?(other)
        (self <=> other).zero?
      end

      def eq?(other)
        eql?(other)
      end

      def ==(other)
        eql?(other)
      end

      def hash
        @build_version.hash
      end

      def to_s
        @build_version
      end
    end
  end
end
