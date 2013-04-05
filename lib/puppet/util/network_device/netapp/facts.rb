require 'puppet/util/network_device/netapp'

class Puppet::Util::NetworkDevice::Netapp::Facts
  
  attr_reader :transport
  
  def initialize(transport)
    @transport = transport
  end
  
  def retreive
    
    # Create empty array
    @facts = {}
    
    # Invoke "system-get-version" to gather system version. 
    result = @transport.invoke("system-get-version")
    
    # Pull out version
    sys_version = result.child_get_string("version")
    
    # Add to facts hash
    @facts['operatingsystem'] = sys_version 
      
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
      'cpu-processor-type'
      ].each do |key|
        @facts[key] = sys_info.child_get_string("#{key}".to_s)
    end
      
    # cleanup of netapp output to match existing facter key values.
    map = { 'system-name'        => 'hostname',
            'memory-size'        => 'memorysize',
            'system-model'       => 'hardwaremodel',
            'cpu-processor-type' => 'processor',
    }
    @facts = Hash[@facts.map {|k, v| [map[k] || k, v] }]\

    # Need to replace '-' with '_'
    @facts = Hash[@facts.map {|k, v| [k.to_s.gsub('-','_'), v] }]

    # Return array to calling class. 
    @facts
    
  end
end
