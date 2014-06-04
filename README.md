# LogMonitor

This gem provides an implementation of a simple log monitor, tested on Ruby 2.1.2.

## Generating the gem

Both bundler and rspec are required to build the gem:

    $ gem install bundler rspec

Run rake -T to see available tasks. The gem can be built with:

    $ rake build

Or, if you want to make sure everything works correctly:

    $ bundle exec rake build

## Installation

After generating the gem, install it using:

    $ gem install pkg/logmonitor-1.0.gem

## Usage

Provided binary is 'logmonitor'. Run it as:

    $ logmonitor --help

to see an usage help message.
