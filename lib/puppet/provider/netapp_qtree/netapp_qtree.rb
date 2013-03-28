require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_qtree).provide(:netapp_qtree, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Qtree creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_qtree: got to self.instances.")
    qtree_instances = Array.new

    # Query Netapp for qtree-list against volume. 
    result = transport.invoke("qtree-list")
    # Check result status. 
    if(result.results_status == "failed")
      # Check required resource state
      Puppet.debug("Puppet::Provider::Netapp_qtree: qtree-list failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Qtree-list failed due to #{result.results_reason}. \n."
      return false
    else 
      # Get a list of qtrees
      qtree_list = result.child_get("qtrees")
      Puppet.debug("Qtree_list looks like:")
      Puppet.debug("#{qtree_list.sprintf()}")
      
      # Create array of children
      qtrees = qtree_list.children_get

      # Itterate through each 'qtree-info' block. 
      qtrees.each do |qtree_info|
 
        # Pull out the qtree name.
        name = qtree_info.child_get_string("qtree")
        # Skip record is 'name' is empty, as it's not actually a qtree. 
        Puppet.debug("Puppet::Provider::Netapp_qtree.prefetch: Checking if this is an actual qtree, not a volume. ")
        next if name.empty?
        Puppet.debug("Puppet::Provider::Netapp_qtree.prefetch: Processing rule for qtree '#{name}'.")
        
        # Construct an export hash for rule
        qtree_hash = { :name => name,
                       :ensure => :present }
        
        # Add the volume details               
        qtree_hash[:volume] = qtree_info.child_get_string("volume") unless qtree_info.child_get_string("volume").empty?
        Puppet.debug("Puppet::Provider::Netapp_qtree.prefetch: Volume for '#{name}' is '#{qtree_info.child_get_string("volume")}'.")

        # Create the instance and add to exports array.
        Puppet.debug("Creating instance for '#{name}'. \n")
        qtree_instances << new(qtree_hash)
      end
      
      Puppet.debug("Processed all qtree instances. ")
    end
  
    # Return the final exports array. 
    Puppet.debug("Returning qtrees array. ")
    qtree_instances
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_qtree: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      #else
      #  resource.provider = new(:nil, :ensure => :absent)
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_qtree: Got to flush for resource #{@resource[:name]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    if @property_hash[:ensure] == :absent
      
      Puppet.debug("Puppet::Provider::Netapp_qtree: Ensure is absent.")
      
      Puppet.debug("Puppet::Provider::Netapp_qtree: destroying Netapp Qtree #{@resource[:name]} against volume #{@resource[:volume]}")
      # Query Netapp to remove qtree against volume. 
      result = transport.invoke("qtree-delete", "qtree", "/vol/#{@resource[:volume]}/#{@resource[:name]}")
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
  end
  
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
    #@property_hash[:ensure] = :present
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_qtree: destroying Netapp Qtree #{@resource[:name]} against volume #{@resource[:volume]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_qtree: checking existance of Netapp qtree #{@resource[:name]} against volume #{@resource[:volume]}")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end
  
end
