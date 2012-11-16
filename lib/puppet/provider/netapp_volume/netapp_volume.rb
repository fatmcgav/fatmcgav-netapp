require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_volume).provide(:netapp_volume, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Volume creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def self.instances
    volumes = transport.invoke("volume-list-info")
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume-list-info failed. \n")
      return false
    else 
      # Pull list of volume-info blocks
      volume_list = volumes.child_get("volumes")
      volume_info = volume_list.children_get()
      volume_info.each do |volume|
        vol_name = volume.child_get_string("name")
        new(:volume => vol_name)
      end
    end
  end
  
  # volume getter/setter
  def volume
    result = {}
      
    volumes = transport.invoke("volume-list-info")
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume-list-info failed. \n")
      return false
    else 
      # Pull list of volume-info blocks
      volume_list = volumes.child_get("volumes")
      volume_info = volume_list.children_get()
      volume_info.each do |volume|
        vol_name = volume.child_get_string("name")
        result[vol_name] = :present
      end
    end
  end
  
  def options
    current_options = {}
    
    # Pull list of volume-options
    output = transport.invoke("volume-options-list-info", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Vol Options: " + output.sprintf() + "\n")
    if(output.results_status == "failed")
      Puppet.debug("Puppet::Provider::netapp_volume: Volume option list failed due to #{output.results_reason}. \n")
      return false
    else
      # Get the options list
      options = output.child_get("options")

      # Get volume-option-info children
      volume_options = options.children_get()
      volume_options.each do |volume_option|
        # Extract values to put into options hash
        name = volume_option.child_get_string("name")
        value = volume_option.child_get_string("value")
        # Construct hash of current options and corresponding value. 
        current_options[name] = value
      end
    end
    
    # Pull out matching option name list
    set_options = @resource[:options].first
    matched_options = set_options.keys & current_options.keys
    
    # Create new results hash 
    result = {}
    matched_options.each do |name|
      Puppet.debug("Puppet::Provider::netapp_volume_options: Matched Name #{name}. Current value = #{[current_options[name]]}. New value = #{[set_options[name]]} \n")
      result[name] = current_options[name] unless current_options[name] == set_options[name]
    end
    Puppet.debug("Puppet::Provider::Netapp_volume: Result is a hash. \n") if result.is_a? Hash
    Puppet.debug("Puppet::Provider::Netapp_volume: Returning result... \n")
    result
  end
  
  def options=(value)
    
    Puppet.debug("Puppet::Provider::Netapp_volume: Got to options= setter... \n")
    opts = value.first
    opts.each do |setting,value|
      # Itterate through each options pair. 
      Puppet.debug("Puppet::Provider::Netapp_volume_options: Setting = #{setting}, Value = #{value}")
      # Call webservice.
      result = transport.invoke("volume-set-option", "volume", @resource[:name], "option-name", setting, "option-value", value)
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_volume_options: Setting of Volume Option #{setting} to #{value} failed against volume #{@resource[:name]} due to #{result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp_volume_options: Setting of Volume Option #{setting} to #{value} failed against volume #{@resource[:name]} due to #{result.results_reason}."
        return false
      else 
        Puppet.debug("Puppet::Provider::Netapp_volume_options: Volume Option #{setting} set against Volume #{@resource[:name]}. \n")
      end
    end
    
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_volume: creating Netapp Volume #{@resource[:name]} of initial size #{@resource[:initsize]} in Aggregate #{@resource[:aggregate]} using space reserve of #{@resource[:spaceres]}.")
    result = transport.invoke("volume-create", "volume", @resource[:name], "size", @resource[:initsize], "containing-aggr-name", @resource[:aggregate], "space-reserve", @resource[:spaceres])
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} creation failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} created successfully. Setting options... \n")
      self.options = @resource[:options]
      #return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_volume: destroying Netapp Volume #{@resource[:name]}")
    # Check if volume is online. 
    vi_result = transport.invoke("volume-list-info", "volume", @resource[:name])
    if(vi_result.results_status == "passed")
      volumes = vi_result.child_get("volumes")
      volume_info = volumes.child_get("volume-info")
      state = volume_info.child_get_string("state")
      if(state == "online")
        Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} is currently online. Offlining... ")
        off_result = transport.invoke("volume-offline", "name", @resource[:name])
        if(off_result.results_status == "failed")
          Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} offline failed due to #{off_result.results_reason}. \n")
          raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} offline failed due to #{off_result.results_reason} \n."
          return false
        else 
          Puppet.debug("Puppet::Provider::Netapp_volume: Volume taken offline successfully. \n")
        end
      end
    end
    destroy_result = transport.invoke("volume-destroy", "name", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Volume destroy output: " + destroy_result.sprintf() + "\n")
    if(destroy_result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} wasn't destroyed due to #{destroy_result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} destroy failed due to #{destroy_result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume destroyed successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_volume: checking existance of Netapp Volume #{@resource[:name]}")
    result = transport.invoke("volume-list-info", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Vol Info: " + result.sprintf() + "\n")
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume doesn't exist. \n")
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume exists. \n")
      return true
    end

  end
  
end
