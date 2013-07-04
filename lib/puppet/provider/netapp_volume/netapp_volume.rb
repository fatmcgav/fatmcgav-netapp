require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_volume).provide(:netapp_volume, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Volume creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix
 
  netapp_commands :vollist => 'volume-list-info'
  netapp_commands :optslist => 'volume-options-list-info'
  netapp_commands :snapschedlist => 'snapshot-get-schedule'
  netapp_commands :volsizeset => 'volume-size'
  netapp_commands :snapresset => 'snapshot-set-reserve'
  netapp_commands :autosizeset => 'volume-autosize-set'
  netapp_commands :voloptset => 'volume-set-option'
  netapp_commands :volcreate => 'volume-create'
  
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_volume: got to self.instances.")
    volumes = []

    # Get init-size details
    volume_info = get_volinfo

    # Itterate through each 'volume-info' block
    volume_info.each do |volume|
      vol_name = volume[:name]
      # Construct required information
      volume_hash = { :name => vol_name,
                      :ensure => :present }

      # Initsize
      # Need to convert from bytes to biggest possible unit
      vol_size_bytes = volume[:size_bytes]
      vol_size_mb = vol_size_bytes / 1024 / 1024
      if vol_size_mb % 1024 == 0
        vol_size_gb = vol_size_mb / 1024
        if vol_size_gb % 1024 == 0
          vol_size_tb = vol_size_gb / 1024
          vol_size = vol_size_tb.to_s + "t"
        else
          vol_size = vol_size_gb.to_s + "g"
        end
      else 
        vol_size = vol_size_mb.to_s + "m"
      end
      volume_hash[:initsize] = vol_size
      
      # Get volume snapreserve
      volume_hash[:snapreserve] = volume[:snap_reserve]
      
      # Get autoincrement setting
      volume_hash[:autoincrement] = volume[:auto_size]
      
      # Get volume options
      volume_hash[:options] = self.get_options(vol_name)
      
      # Get volume snapschedule
      volume_hash[:snapschedule] = self.get_snapschedule(vol_name) 
      
      Puppet.debug("Puppet::Provider::Netapp_volume self.instances: Constructed volume_hash for volume #{vol_name}.")

      # Create the instance and add to volumes array.
      volumes << new(volume_hash)
    end
    
    Puppet.debug("Returning volumes array.")
    volumes
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_volume: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end
  
  def flush
    Puppet.debug("Puppet::Provider::Netapp_volume: Got to flush for resource #{@resource[:name]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    if @property_hash[:ensure] == :absent
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
    
    @property_hash.clear
  end
  
  # 
  ## Getters
  #
  
  # Volume info getter
  def self.get_volinfo
    Puppet.debug("Puppet::Provider::Netapp_volume get_volinfo: getting volume info for all volumes.")
        
    # Pull back current volume-size.
    result = vollist("verbose", "true")
    Puppet.debug("Puppet::Provider::Netapp_volume get_volinfo: Pulling back volumes array. \n")
    volume_info = []
    # Get the volume_size value. 
    volumes = result.child_get("volumes")
    volumes_info = volumes.children_get()
    
    # Itterate through the volume-info blocks
    volumes_info.each do |volume|
      # Pull out relevant info
      vol_name = volume.child_get_string("name")
      vol_size_bytes = volume.child_get_int("size-total")
      vol_snap_reserve = volume.child_get_int("snapshot-percent-reserved")
      # Get Auto size settings.
      vol_auto_size = volume.child_get("autosize")
      vol_auto_size = vol_auto_size.child_get("autosize-info")
      vol_auto_size = vol_auto_size.child_get_string("is-enabled")
      
      Puppet.debug("Puppet::Provider::Netapp_volume get_volinfo: Vol_name = #{vol_name}, vol_size_bytes = #{vol_size_bytes}, vol_snap_reserve = #{vol_snap_reserve}, vol_auto_size = #{vol_auto_size}.")

      # Construct hash
      vol_info = { :name         => vol_name, 
                   :size_bytes   => vol_size_bytes,
                   :snap_reserve => vol_snap_reserve,
                   :auto_size    => vol_auto_size }

      # Add to array
      volume_info << vol_info
      Puppet.debug("Processed all volumes. Returning info array.")
      # Return volume_info array
      volume_info
    end
  end
  
  # Volume options getter
  def self.get_options(name)
    Puppet.debug("Puppet::Provider::Netapp_volume get_options: getting current volume options for Volume #{name}")
    
    # Create hash for current_options
    current_options = {}
    
    # Pull list of volume-options
    output = optslist("volume", name)
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
    
    # Return current_options
    current_options
  end

  # Snapshot schedule getter.
  def self.get_snapschedule(name)
    Puppet.debug("Puppet::Provider::Netapp_volume get_snapschedule: checking current volume snapshot schedule for Volume #{name}.")
        
    # Create hash for current_options
    current_schedule = {}
      
    # Create array of schedule keys we're interested in. 
    keys = ['minutes', 'hours', 'days', 'weeks', 'which-hours', 'which-minutes']
    
    # Pull list of volume-options
    output = snapschedlist("volume", name)
    # Get the schedule information list
    keys.each do |key|
        # Get the value for key. 
        value = output.child_get_string(key)
        Puppet.debug("Puppet::Provider::Netapp_volume get_snapschedule: Key = #{key} Value = #{value} \n")
        current_schedule[key] = value
    end
    
    # Return current_schedule hash. 
    current_schedule
  end  
  
  #
  ## Setters
  #
  
  # Volume initsize setter
  def initsize=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume initsize=: setting volume size for Volume #{@resource[:name]}")
        
    # Query Netapp to update volume size. 
    result = volsizeset("volume", @resource[:name], "new-size", @resource[:initsize])
    Puppet.debug("Puppet::Provider::Netapp_volume initsize=: Volume size set succesfully for volume #{@resource[:name]}. \n")
    # Trigger and autoincrement run.
    self.send('autoincrement=', resource['autoincrement'.to_sym]) if resource['autoincrement'.to_sym]
    return true
  end
  
  # Snap reserve setter
  def snapreserve=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume snapreserve=: setting snap reservation value for Volume #{@resource[:name]}")
    
    # Query Netapp to set snap-reserve value. 
    result = snapresset("volume", @resource[:name], "percentage", @resource[:snapreserve])
    Puppet.debug("Puppet::Provider::Netapp_volume snapreserve=: Snap reserve set succesfully for volume #{@resource[:name]}. \n")
    return true
  end
  
  # Autoincrement setter
  def autoincrement=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: setting auto-increment for Volume #{@resource[:name]}")

    # Need to work out a sensible auto-increment size
    # Max growth of 20%, increment of 5%
    size, unit = @resource[:initsize].match(/^(\d+)([A-Z])$/i).captures

    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: Volume size = #{size}, unit = #{unit}.")

    # Need to convert size into MB... 
    if unit == 'g'
      size = size.to_i * 1024
    elsif unit == 't'
      size = size.to_i * 1024 * 1024
    end
    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: Volume size in m = #{size}.")

    # Set max-size
    maxsize = (size.to_i*1.2).to_i
    incrsize = (size.to_i*0.05).to_i
    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: Maxsize = #{maxsize}, incrsize = #{incrsize}.")

    # Query Netapp to set autosize status.
    result = autosizeset("volume", @resource[:name], "is-enabled", @resource[:autoincrement], "maximum-size", maxsize.to_s + "m", "increment-size", incrsize.to_s + "m")
    Puppet.debug("Puppet::Provider::Netapp_volume autoincrement=: Auto-increment set succesfully for volume #{@resource[:name]}. \n")
    return true
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
      result = voloptset("volume", @resource[:name], "option-name", setting, "option-value", value)
      Puppet.debug("Puppet::Provider::Netapp_volume  options=: Volume Option #{setting} set against Volume #{@resource[:name]}. \n")
    end
    # All volume options set successfully. 
    Puppet.debug("Puppet::Provider::Netapp_volume options=: Volume Options set against Volume #{@resource[:name]}. \n")
    return true
    
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
    result = transport.invoke_elem(opts)
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
    result = volcreate("volume", @resource[:name], "size", @resource[:initsize], "containing-aggr-name", @resource[:aggregate], "language-code", @resource[:languagecode], "space-reserve", @resource[:spaceres])
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
    
    return true
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_volume: destroying Netapp Volume #{@resource[:name]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_volume: checking existance of Netapp Volume #{@resource[:name]}")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end
  
end
