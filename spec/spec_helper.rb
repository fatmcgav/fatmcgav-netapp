require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |support_file|
  require support_file
end

class Object
  alias :must :should
  alias :must_not :should_not
end

# Simplecov for Teamcity
begin
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/lib/puppet/util/network_device/netapp/Na'
    #at_exit do
    #  SimpleCov::Formatter::TeamcitySummaryFormatter.new.format(SimpleCov.result) if ENV['TEAMCITY_VERSION']
    #end
  end
rescue Exception => e
  warn "Simplecov disabled"
end
