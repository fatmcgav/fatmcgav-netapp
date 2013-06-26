require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |support_file|
  require support_file
end

class Object
  alias :must :should
  alias :must_not :should_not
end
