# frozen_string_literal: true

source('https://rubygems.org')

ruby '3.1.1'

# Provides a consistent environment for Ruby projects by tracking and installing exact gem versions.
gem 'bundler'
# Automation tool for mobile developers.
gem 'fastlane', '>= 2.228.0'
# Provides an interactive debugging environment for Ruby.
gem 'pry'
# A simple task automation tool.
gem 'rake'
# Behavior-driven testing tool for Ruby.
gem 'rspec'
# Formatter for RSpec to generate JUnit compatible reports.
gem 'rspec_junit_formatter'
# A Ruby static code analyzer and formatter.
gem 'rubocop'
# A collection of RuboCop cops for performance optimizations.
gem 'rubocop-performance'
# A RuboCop extension focused on enforcing tools.
gem 'rubocop-require_tools'
# SimpleCov is a code coverage analysis tool for Ruby.
gem 'simplecov'

# Until Fastlane suports Ruby 3.4 oficially and includes gems below directly.
# https://github.com/fastlane/fastlane/issues/29183#issuecomment-2567093826
# PR: https://github.com/fastlane/fastlane/pull/29184
gem 'abbrev'
gem 'mutex_m'
gem 'ostruct'

# Until Fastlane suports Ruby 3.5 oficially and includes gems below directly.
gem 'logger'

gemspec

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
