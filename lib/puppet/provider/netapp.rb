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
      # The `create_class_and_instance_method` method was added in puppet 3.0.0
      create_class_and_instance_method(name) do |*args|
        Puppet.debug("apicommand is a - #{apicommand.class}")
        if apicommand.is_a?(Hash) && apicommand[:iter]
          Puppet.debug("Got an iter request, for #{apicommand[:result_element]} element.")
          result = netapp_itterate(apicommand[:api], apicommand[:result_element])
        else
          Puppet.debug("Executing api call #{[apicommand, args].flatten.join(' ')}")
          result = transport.invoke(apicommand, *args)
          if result.results_status == 'failed'
            raise Puppet::Error, "Executing api call #{[apicommand, args].flatten.join(' ')} failed: #{result.results_reason.inspect}"
          end
        end
        
        # Return the results
        result
      end
    end
  end
  
  # Helper function for itterating over an itterative api call
  def self.netapp_itterate(api,result_element)
    Puppet.debug("Got to netapp_itterate. API = #{api}, result_element = #{result_element}")
    
    # Initial vars
    tag = ""
    results = []
      
    # Itterate over the api
    while !tag.nil?
      # Invoke api request
      Puppet.debug("Invoking: [#{api}, \"tag\", #{tag}]")
      output = transport.invoke(api, "tag", tag)
      if output.results_status == 'failed'
        raise Puppet::Error, "Executing api call #{[api,"tag",tag].flatten.join(' ')} failed: #{output.results_reason.inspect}"
      end
      
      # Check if any results were actually returned
      records_returned = output.child_get_int("num-records")
      if records_returned == 0
        Puppet.debug("No records returned on this call...")
        return
      end
      
      # Update tag
      tag = output.child_get_string("next-tag")
      
      # Get the result_element and push into results array
      element = output.child_get(result_element)
      results.push(*element.children_get())
    end
    
    # We're done itterating
    Puppet.debug("Finished itterating over api. Returning results")
    results
  end

end
