# First line of spec/spec_helper.rb
begin
require 'codeclimate-test-reporter'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter ]
SimpleCov.start do
  add_filter '/spec/'
  # Exclude bundled Gems in `/.vendor/`
  add_filter '/.vendor/'
end
rescue LoadError => e
 puts e.to_s
end

require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
    c.formatter = 'documentation'
    c.mock_with :rspec
end
