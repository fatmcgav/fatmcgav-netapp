require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_volume).provide(:netapp_volume, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Volume creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_volume: creating Netapp Volume #{resource[:name]}")
    #transport[wsdl].create(resource[:name], [0])
    
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_volume: destroying Netapp Volume #{resource[:name]}")
    #transport[wsdl].delete_node_address(resource[:name])
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_volume: checking existance of Netapp Volume #{resource[:name]}")
    transport.invoke("volume-list-info").include?(resource[:name])
  end
  
end