require 'puppet/util/network_device/netapp'

class Puppet::Util::NetworkDevice::Netapp::Facts
  
  attr_reader :transport
  
  def initialize(transport)
    @transport = transport
  end
  
  def retreive
    
    # Create empty array
    @facts = {}
    
    # Invoke "system-get-info" call to gather system information. 
    result = @transport.invoke("system-get-info")
    
    # Pull out system-info subset. 
    sys_info = result.child_get("system-info")
    
    [ 'system-name',
      'system-id',
      'system-model',
      'system-machine-type',
      'system-serial-number',
      'partner-system-id',
      'partner-serial-number',
      'system-revision',
      'number-of-processors',
      'memory-size',
      ].each do |key|
        @facts[key] = sys_info.child_get_string("#{key}".to_s)
    end
      
    # Return array to calling class. 
    @facts
    
  end
end