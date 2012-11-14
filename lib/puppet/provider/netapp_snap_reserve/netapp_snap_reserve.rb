require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_snap_reserve).provide(:netapp_snap_reserve, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Snap Reserve percentage setting."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_snap_reserve: Setting snap reserve to #{@resource[:reserved]}% for #{@resource[:name]}.")
    # Query Netapp to create qtree against volume. . 
    result = transport.invoke("snapshot-set-reserve", "volume", @resource[:name], "percentage", @resource[:reserved])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_snap_reserve: Setting of snap reserve for volume #{@resource[:name]} failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_snap_reserve: Setting of snap reserve for volume #{@resource[:name]} failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_snap_reserve: Snap reserve set succesfully for volume #{@resource[:name]}. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_snap_reserve: destroy not supported for Netapp_snap_reserve provider. \n")
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_snap_reserve: checking current snap reserve for volume #{@resource[:name]}. \n")
    # Query Netapp for qtree-list against volume. 
    result = transport.invoke("snapshot-get-reserve", "volume", @resource[:name])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_snap_reserve: snapshot-get-reserve failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp snapshot-get-reserve failed due to #{result.results_reason} \n."
      return false
    else 
      # Get a list of qtrees
      current_reserve = result.child_get("percent-reserved")
      Puppet.debug("Puppet::Provider::Netapp_snap_reserve: Current snap reserve is #{current_reserve}. \n")
      
      # Compare current to requested.
      if(current_reserve != @resource[:reserved])
        Puppet.debug("Puppet::Provider::Netapp_snap_reserve: Current snap reserve and requested snap reserve do not match. \n")
        return false
      else
        # Current snap reserve and requested snap reserve match.  
        Puppet.debug("Puppet::Provider::Netapp_snap_reserve: Current snap reserve and requested snap reserve do match. \n")
        return true
      end
    end

  end
  
end