# frozen_string_literal: true

require_relative '../../spec_helper'

# Took iOS SDK versions from https://xcodereleases.com/

RSpec.describe Fastlane::CreateSimulatorDevices::AppleBuildVersion do
  describe '#initialize' do
    it 'initializes with a build version string' do
      # GIVEN: A build version string
      build_version = '22E238'

      # WHEN: Creating a new AppleBuildVersion instance
      sut = described_class.new(build_version)

      # THEN: The instance should be properly initialized
      expect(sut).to be_a(described_class)
      expect(sut.to_s).to eq(build_version)
    end
  end

  describe '#to_s' do
    it 'returns the build version string' do
      # GIVEN: An AppleBuildVersion instance
      build_version = '22E238'
      sut = described_class.new(build_version)

      # WHEN: Converting to string
      result = sut.to_s

      # THEN: Should return the original build version
      expect(result).to eq(build_version)
    end
  end

  describe '#<' do
    it 'correctly compares non-beta versions' do
      # GIVEN: Two non-beta build versions (length < 8)
      smaller_version = described_class.new('22E235') # iOS 18.4
      bigger_version = described_class.new('22F76') # iOS 18.5

      # THEN: Comparing them should return true since '22E235' < '22F76'
      expect(smaller_version < bigger_version).to be_truthy
      # THEN: Comparing them should return true since '22F76' > '22E235'
      expect(bigger_version > smaller_version).to be_truthy
    end

    it 'correctly compares beta versions' do
      # GIVEN: Two beta build versions (length >= 8)
      smaller_version = described_class.new('23A5260k') # iOS 26.0 Beta 2
      bigger_version = described_class.new('23A5276f') # iOS 26.0 Beta 1

      # THEN: Comparing them should return true since '23A5260k' < '23A5276f'
      expect(smaller_version < bigger_version).to be_truthy
      # THEN: Comparing them should return true since '23A5276f' > '23A5260k'
      expect(bigger_version > smaller_version).to be_truthy
    end

    it 'correctly compares beta vs non-beta versions for the same SDK version' do
      # GIVEN: Non-beta versions but one is RC, another Release.
      beta_version = described_class.new('22A348') # iOS 16.0 RC1
      non_beta_version = described_class.new('22A3362') # iOS 16.0 Release

      # THEN: Comparing them should return true since '22A3362' < '22A348'
      expect(beta_version < non_beta_version).to be_truthy
      # THEN: Comparing them should return true since '22A348' > '22A3362'
      expect(non_beta_version > beta_version).to be_truthy
    end

    it 'correctly compares versions from different SDKs' do
      # GIVEN: Two different verions with different SDKs
      smaller_version = described_class.new('21F77') # iOS 15.4 Release
      bigger_version = described_class.new('22A3362') # iOS 16.0 Release

      # THEN: Comparing them should return true since '21F77' < '22A3362'
      expect(smaller_version < bigger_version).to be_truthy
      # THEN: Comparing them should return true since '22A3362' > '21F77'
      expect(bigger_version > smaller_version).to be_truthy
    end
  end

  describe '#eql?' do
    it 'returns true for equal build versions' do
      # GIVEN: Two AppleBuildVersion instances with same build version
      version1 = described_class.new('22E238')
      version2 = described_class.new('22E238')

      # THEN: Comparing them should return true since they are equal
      expect(version1.eql?(version2)).to be_truthy
    end

    it 'returns false for different build versions' do
      # GIVEN: Two AppleBuildVersion instances with different build versions
      version1 = described_class.new('22E238')
      version2 = described_class.new('22E239')

      # THEN: Comparing them should return false since they are not equal
      expect(version1.eql?(version2)).to be_falsey
    end
  end
end
