require 'pry'
require 'pp'
require 'tapp'
require 'awesome_print'
require 'simplecov'
require 'coveralls'
require 'parslet/rig/rspec'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])

SimpleCov.start do
  add_filter '/spec/'
end
