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
  
  # Volume info getter
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
  
  # Snap reserve getter
  def snapreserve
    Puppet.debug("Puppet::Provider::Netapp_volume snapreserve: checking current snap reservation value for Volume #{@resource[:name]}")
    
    # Pull back current snap-reserve value.
    result = transport.invoke("snapshot-get-reserve", "volume", @resource[:name])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume snapreserve: snapshot-get-reserve failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Provider::Netapp_volume snapshot-get-reserve failed due to #{result.results_reason} \n."
      return false
    else 
      # Get a list of qtrees
      current_reserve = result.child_get_int("percent-reserved")
      Puppet.debug("Puppet::Provider::Netapp_volume snapreserve: Current snap reserve is #{current_reserve}. \n")
      
      # Return current_reserve value
      current_reserve
    end
  end
  
  # Snap reserve setter
  def snapreserve=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume snapreserve=: setting snap reservation value for Volume #{@resource[:name]}")
    
    # Query Netapp to create qtree against volume. . 
    result = transport.invoke("snapshot-set-reserve", "volume", @resource[:name], "percentage", @resource[:snapreserve])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume snapreserve=: Setting of snap reserve for volume #{@resource[:name]} failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Provider::Netapp_volume snapreserve=: Setting of snap reserve for volume #{@resource[:name]} failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume snapreserve=: Snap reserve set succesfully for volume #{@resource[:name]}. \n")
      return true
    end
  end
  
  # Autoincremenet getter
  def autoincrement
    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement: checking current auto increment value for Volume #{@resource[:name]}")
    
    # Pull back current snap-reserve value.
    result = transport.invoke("volume-autosize-get", "volume", @resource[:name])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume autoincrement: volume-autosize-get failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Provider::Netapp_volume volume-autosize-get failed due to #{result.results_reason} \n."
      return false
    else 
      # Get a list of qtrees
      autoincrement = result.child_get_string("is-enabled")
      Puppet.debug("Puppet::Provider::Netapp_volume autoincrement: Current autoincrement setting is #{autoincrement}. \n")
      
      # Return current_reserve value
      autoincrement
    end
  end
  
  # Autoincrement setter
  def autoincrement=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: setting auto-increment for Volume #{@resource[:name]}")
    
    # Query Netapp to create qtree against volume. . 
    result = transport.invoke("volume-autosize-set", "volume", @resource[:name], "is-enabled", @resource[:autoincrement])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: Setting of auto-increment for volume #{@resource[:name]} failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Provider::Netapp_volume autoincrement=: Setting of auto-increment for volume #{@resource[:name]} failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: Auto-increment set succesfully for volume #{@resource[:name]}. \n")
      return true
    end
  end
  
  # Volume options getter
  def options
    Puppet.debug("Puppet::Provider::Netapp_volume options: checking current volume options for Volume #{@resource[:name]}")
    
    # Create hash for current_options
    current_options = {}
    
    # Pull list of volume-options
    output = transport.invoke("volume-options-list-info", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Vol Options: " + output.sprintf() + "\n")
    if(output.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume options: Volume option list failed due to #{output.results_reason}. \n")
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
      Puppet.debug("Puppet::Provider::Netapp_volume options: Matched Name #{name}. Current value = #{[current_options[name]]}. New value = #{[set_options[name]]} \n")
      result[name] = current_options[name]
    end
    Puppet.debug("Puppet::Provider::Netapp_volume options: Returning result hash... \n")
    result
  end
  
  # Volume options setter. 
  def options=(value)
    
    Puppet.debug("Puppet::Provider::Netapp_volume options=: Got to options= setter... \n")
    # Value is an array, so pull out first value. 
    opts = value.first
    opts.each do |setting,value|
      # Itterate through each options pair. 
      Puppet.debug("Puppet::Provider::Netapp_volume options=: Setting = #{setting}, Value = #{value}")
      # Call webservice to set volume option.
      result = transport.invoke("volume-set-option", "volume", @resource[:name], "option-name", setting, "option-value", value)
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_volume options=: Setting of Volume Option #{setting} to #{value} failed against volume #{@resource[:name]} due to #{result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp_volume options=: Setting of Volume Option #{setting} to #{value} failed against volume #{@resource[:name]} due to #{result.results_reason}."
        return false
      else 
        Puppet.debug("Puppet::Provider::Netapp_volume  options=: Volume Option #{setting} set against Volume #{@resource[:name]}. \n")
      end
    end
    # All volume options set successfully. 
    Puppet.debug("Puppet::Provider::Netapp_volume options=: Volume Options set against Volume #{@resource[:name]}. \n")
    return true
    
  end
  
  # Snapshot schedule getter.
  def snapschedule
    Puppet.debug("Puppet::Provider::Netapp_volume snapschedule: checking current volume snapshot schedule for Volume #{@resource[:name]}")
        
    # Create hash for current_options
    current_schedule = {}
      
    # Create array of schedule keys we're interested in. 
    keys = ['minutes', 'hours', 'days', 'weeks']
    
    # Pull list of volume-options
    output = transport.invoke("snapshot-get-schedule", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume snapschedule: Vol Snapshot Schedule: " + output.sprintf() + "\n")
    if(output.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume snapschedule: Volume snapshot schedule get failed due to #{output.results_reason}. \n")
      return false
    else
      # Get the schedule information list
      keys.each do |key|
          # Get the value for key. 
          value = out.child_get_int(key)
          Puppet.debug("Puppet::Provider::Netapp_volume snapschedule: Key = #{key} Value = #{value.to_s} \n")
          current_schedule[key] = value
      end
    end
    
    # Return current_schedule hash. 
    current_schedule
  end
  
# Snapshot schedule setter.
  def snapschedule=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume snapschedule=: Got to snapschedule= setter... \n")
    # Value is an array, so pull out first value. 
    snapschedule = value.first
    
    # Create a new NaElement object
    opts = NaElement.new('snapshot-set-schedule')
    opts.child_add_string('volume', @resource[:name])
    
    # Itterate through snapschedule hash
    snapschedule.each do |key,value|
      Puppet.debug("Puppet::Provider::Netapp_volume snapschedule=: Key = #{key}, Value = #{value}. \n")
      opts.child_add_string(key, value.to_s)
    end
    
    # Call webservice to set schedule. 
    results = transport.invoke_elem(opts)
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume snapschedule=: Setting of Snapschedule failed for volume #{@resource[:name]} due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_volume snapschedule=: Setting of Snapschedule failed for volume #{@resource[:name]} due to #{result.results_reason}."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume snapschedule=: Snapshedule successfully set against Volume #{@resource[:name]}. \n")
    end
    return true
  end
  
  # Volume create. 
  def create
    Puppet.debug("Puppet::Provider::Netapp_volume: creating Netapp Volume #{@resource[:name]} of initial size #{@resource[:initsize]} in Aggregate #{@resource[:aggregate]} using space reserve of #{@resource[:spaceres]}.")
    # Call webservice to create volume. 
    result = transport.invoke("volume-create", "volume", @resource[:name], "size", @resource[:initsize], "containing-aggr-name", @resource[:aggregate], "language-code", @resource[:languagecode], "space-reserve", @resource[:spaceres])
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} creation failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} created successfully. Setting options... \n")
      
      # Update other attributes after resource creation. 
      methods = [
        'autoincrement',
        'options',
        'snapreserve',
        'snapschedule'
        ]
      
      # Itterate through methods. 
      methods.each do |method|
        self.send("#{method}=", resource[method.to_sym]) if resource[method.to_sym]
      end
      #self.options = @resource[:options]
      
      return true
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
    # Call webservice to list volume info
    result = transport.invoke("volume-list-info", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Vol Info: " + result.sprintf() + "\n")
    # Check response status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume doesn't exist. \n")
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume exists. \n")
      return true
    end

  end
  
end
