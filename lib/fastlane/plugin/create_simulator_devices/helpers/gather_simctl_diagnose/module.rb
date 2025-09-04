# frozen_string_literal: true

require 'fastlane'

module Fastlane
  # Gather simctl diagnose data.
  module GatherSimctlDiagnose
    UI = ::Fastlane::UI unless defined?(UI)
  end
end
