# create_simulator_devices plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-create_simulator_devices)

## About create_simulator_devices

This action creates simulator devices.

Usage sample:

```ruby
available_simulators_list = create_simulator_devices(
  devices: ['iPhone 15 (17.0)', 'iPhone 16', 'iPhone 14 (16.3)']
  verbose: false
)
# or
available_simulators_list = create_simulator_devices(
  devices: 'iPhone 15 (17.0), iPhone 16,iPhone 14 (16.3)'
  verbose: false
)
# Then run tests with a available_simulators_list
run_tests(
  devices: available_simulators_list
)
```

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-create_simulator_devices`, add it to your project by running:

```bash
fastlane add_plugin create_simulator_devices
```

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

# Contributions

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
