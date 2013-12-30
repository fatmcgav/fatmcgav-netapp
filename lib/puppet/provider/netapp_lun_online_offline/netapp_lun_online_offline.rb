require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_lun_online_offline).provide(:netapp_lun_online_offline, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Lun online/offline."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :lunlist        => 'lun-list-info'
  netapp_commands :lunoffline     => 'lun-offline'
  netapp_commands :lunonline      => 'lun-online'

  def get_lun_status
    lun_status = 'offline'
    Puppet.debug("Fetching Lun information")
    result = lunlist("path", @resource[:name])
    Puppet.debug(" Lun informations - #{result}")
    luns = result.child_get("luns")
    luns_info = luns.children_get()
    # Iterate through the luns-info blocks
    luns_info.each do |lun|
      # Pull out relevant info
      lun_state = lun.child_get_string("online")

      if ((lun_state != nil) && (lun_state == "true"))
        lun_status = 'online'
      end
    end
    return lun_status
  end

  def get_create_command
    arguments = ["path", @resource[:name]]
    if @resource[:force] == :true
      arguments +=["force", @resource[:force]]
    end
    return arguments
  end

  def create
    Puppet.debug("Inside create method.")
    Puppet.info("Making LUN '#{@resource[:name]}' online")
    lun_status = get_lun_status
    Puppet.debug("Current Lun status after executing online operation - #{lun_status}")
    if  "#{lun_status}" == "offline"
      lunonline(*get_create_command)
      lun_status = get_lun_status
      if  "#{lun_status}" == "online"
        Puppet.info("LUN '#{@resource[:name]}' bought online successfully")
      else
        #Puppet.info("Failed to destroy the LUN '@resource[:name]'")
        raise Puppet::Error, "Failed to online the LUN '#{@resource[:name]}'"
      end
    else
      Puppet.info("LUN '#{@resource[:name]}' already in online state")
    end
  end

  def destroy
    Puppet.debug("Inside destroy method.")
    Puppet.info("Making LUN '#{@resource[:name]}' offline")
    lun_status = get_lun_status
    Puppet.debug("Current Lun status after executing offline operation - #{lun_status}")
    if  "#{lun_status}" == "online"
      lunoffline("path", @resource[:name])
      lun_status = get_lun_status
      if  "#{lun_status}" == "offline"
        Puppet.info("LUN '#{@resource[:name]}' bought offline successfully")
      else
        #Puppet.info("Failed to destroy the LUN '@resource[:name]'")
        raise Puppet::Error, "Failed to offline the LUN '#{@resource[:name]}'"
      end
    else
      Puppet.info("LUN '#{@resource[:name]}' already in offline state")
    end
  end

  def exists?
    Puppet.debug("Inside exists method.")
    lun_status = get_lun_status
    if  "#{lun_status}" == "offline"
      Puppet.debug("Lun status before executing any online/offline operation - #{lun_status}")
      false
    else
      Puppet.debug("Lun status before executing any online/offline operation - #{lun_status}")
      true
    end
  end
  
end

