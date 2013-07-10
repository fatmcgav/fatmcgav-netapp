require 'puppet/provider'
require 'puppet/util/network_device/netapp/device'

class Puppet::Provider::Netapp < Puppet::Provider

  attr_accessor :device

  def self.transport
    if Facter.value(:url) then
      Puppet.debug "Puppet::Util::NetworkDevice::Netapp: connecting via facter url."
      @device ||= Puppet::Util::NetworkDevice::Netapp::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Netapp: device not initialized #{caller.join("\n")}" unless @device
    end

    @tranport = @device.transport
  end

  def transport
    # this calls the class instance of self.transport instead of the object instance which causes an infinite loop.
    self.class.transport
  end

  # Helper function for simplifying the execution of NetApp API commands, in a similar fashion to the commands function. 
  # Arguments should be a hash of 'command name' => 'api command'.
  def self.netapp_commands(command_specs)
    command_specs.each do |name, apicommand|
      create_class_and_instance_method(name) do |*args|
        debug "Executing api call #{[apicommand, args].flatten.join(' ')}"
        result = transport.invoke(apicommand, *args)
        if result.results_status == 'failed'
          raise Puppet::Error, "Executing api call #{[apicommand, args].flatten.join(' ')} failed: #{result.results_reason.inspect}"
        end
        result
      end
    end
  end
  
  # Helper function to wrap around the Netapp invoke_elem function, 
  # to check the result code and return as appropriate.
  def netapp_invoke(request)
    debug 'Executing invoke_elem api.'
    result = transport.invoke_elem(request)
    if result.result_status == 'failed'
      raise Puppet::Error, "Executing invoke_elem api call failed: #{result.results_reason.inspect}"
    end
    result
  end 
  
end
