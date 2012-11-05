require 'puppet/util/network_device/netapp'

class Puppet::Util::NetworkDevice::Netapp::Facts
  
  attr_reader :transport
  
  def initialize(transport)
    @transport = transport
  end
  
  def retreive
    
    @facts = {}
    @facts
    
  end
end