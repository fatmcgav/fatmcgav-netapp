require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_qtree).provide(:netapp_qtree, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Qtree creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_qtree: creating Netapp Qtree #{@resource[:name]} on volume #{@resource[:volume]}.")
    # Query Netapp to create qtree against volume. . 
    result = transport.invoke("qtree-create", "qtree", @resource[:name], "volume", @resource[:volume])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_qtree: Qtree #{@resource[:name]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Qtree #{@resource[:name]} creation failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_qtree: Qtree #{@resource[:name]} created successfully on volume #{@resource[:volume]}. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_qtree: destroying Netapp Qtree #{@resource[:name]} against volume #{@resource[:volume]}")
    # Query Netapp to remove qtree against volume. 
    result = transport.invoke("qtree-delete", "qtree", @resource[:name])
    # Check result returned. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_qtree: qtree #{@resource[:name]} wasn't destroyed due to #{destroy_result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp qtree #{@resource[:name]} destroy failed due to #{destroy_result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_qtree: qtree #{@resource[:name]} destroyed successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_qtree: checking existance of Netapp qtree #{@resource[:name]} against volume #{@resource[:volume]}")
    # Query Netapp for qtree-list against volume. 
    result = transport.invoke("qtree-list", "volume", @resource[:volume])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_qtree: qtree-list failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Qtree-list failed due to #{result.results_reason} \n."
      return false
    else 
      # Get a list of qtrees
      qtree_list = result.child_get("qtrees")
      qtrees = qtree_list.children_get
      # Itterate through each 'qtree-info' block. 
      qtrees.each do |qtree|
        # Check if the qtree name tag matches the resource name we're validating. 
        if(qtree.child_get_string("qtree") == @resource[:name])
          # Match found, return true. 
          Puppet.debug("Puppet::Provider::Netapp_qtree: Matching qtree exists. \n")
          return true
        end
      end
      
      # No match found, therefore doesn't exist. Return false.  
      Puppet.debug("Puppet::Provider::Netapp_qtree: Matching qtree doesn't exist. \n")
      return false
    end

  end
  
end