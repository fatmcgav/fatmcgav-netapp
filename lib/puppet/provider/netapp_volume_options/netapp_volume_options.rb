require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_volume_options).provide(:netapp_volume_options, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Volume option modification and deletion for existing volumes."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::netapp_volume_options: setting Netapp Volume options against volume #{@resource[:name]}.")
    options = @resource[:options]
    options.each do |option|
      Puppet.debug("Puppet::Provider::netapp_volume_options: Option: #{option}")
      # Split the option value on '='.
      value = option.split('=')
      # Pick out the name and corresponding setting.
      name = value[0]
      setting = value[1]
      Puppet.debug("Puppet::Provider::netapp_volume_options: Name = #{name}, Setting = #{setting}")
    end
    result = transport.invoke("volume-set-option", "volume", @resource[:name], "option-name", name, "option-value", value)
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::netapp_volume_options: Volume #{@resource[:name]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} creation failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::netapp_volume_options: Volume #{@resource[:name]} created successfully. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::netapp_volume_options: destroy not required for netapp_volume_options provider. \n")
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
      Puppet.debug("Puppet::Provider::netapp_volume_options: Volume exists. \n")
      return true
    end

  end
  
end