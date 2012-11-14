require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_volume_options).provide(:netapp_volume_options, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Volume option modification and deletion for existing volumes."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_volume_options: setting Netapp Volume options against volume #{@resource[:name]}.")
    setoptions = @resource[:options]
    setoptions.each do |setting,value|
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
    # If we got here, all options were set correctly. 
    Puppet.debug("Puppet::Provider::Netapp_volume_options: Volume Options set successfully against Volume #{@resource[:name]}. \n")
    return true
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::netapp_volume_options: destroy not supported for netapp_volume_options provider. \n")
  end

  def exists?
    Puppet.debug("Puppet::Provider::netapp_volume_options: checking settings for NetApp Volume #{@resource[:name]}")
    result = transport.invoke("volume-options-list-info", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::netapp_volume_options: Vol Options: " + result.sprintf() + "\n")
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::netapp_volume_options: Volume option list failed due to #{result.results_reason}. \n")
      return false
    else
      # Need to check the response against the list of options we're trying to set.
      output = result.child_get("options")
      # Create hash to store retrieved options
      cur_options = {}
      # Get volume-option-info children
      volume_options = output.children_get()
      volume_options.each do |volume_option|
        name = volume_option.child_get_string("name")
        value = volume_option.child_get_string("value")
        # Construct hash of current options and corresponding value. 
        cur_options[name] = value
      end
      set_options = @resource[:options]
      # Get list of matching options. 
      matched_options = set_options.keys & cur_options.keys
      matched_options.each do |name|
        Puppet.debug("Puppet::Provider::netapp_volume_options: Matched Name #{name}. Current value = #{[cur_options[name]]}. New value = #{[set_options[name]]} \n")
        # Compare the current value with the setter value. 
        if([cur_options[name]] != [set_options[name]])
                Puppet.debug("Puppet::Provider::netapp_volume_options: #{name} values don't match. \n")
                return false
        end
      end
      Puppet.debug("Puppet::Provider::netapp_volume_options: Volume options all match. \n")
      return true
    end
  end

  
end