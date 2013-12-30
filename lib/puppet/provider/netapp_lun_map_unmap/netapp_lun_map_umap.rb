require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_lun_map_unmap).provide(:netapp_lun_map_unmap, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Lun map/unmap operations."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :lunmaplist     => 'lun-map-list-info'
  netapp_commands :lunmap         => 'lun-map'
  netapp_commands :lununmap       => 'lun-unmap'
  def get_lun_mapped_status
    lun_mapped_status = 'false'
    Puppet.debug("Fetching Lun information")
    result = lunmaplist("path", @resource[:name])
    Puppet.debug(" Lun informations - #{result}")

    initiator_groups = result.child_get("initiator-groups")
    initiator_group_info = initiator_groups.children_get()

    # Itterate through the luns-info blocks
    initiator_group_info.each do |group|
      # Pull out relevant info
      group_name = group.child_get_string("initiator-group-name")

      if ((group_name != nil) && (@resource[:initiatorgroup] == group_name))
        lun_mapped_status = 'true'
      end
    end

    return lun_mapped_status

  end

  def get_create_command
    arguments = ["path", @resource[:name], "initiator-group", @resource[:initiatorgroup]]
    if @resource[:force] == :true
      arguments +=["force", @resource[:force]]
    end

    if ((@resource[:lunid]!= nil) && (@resource[:lunid].length > 0))
      arguments +=["lun-id", @resource[:lunid]]
    end

    return arguments
  end

  def get_destroy_command
    arguments = ["path", @resource[:name], "initiator-group", @resource[:initiatorgroup]]

    return arguments
  end

  def create
    Puppet.debug("Inside create method.")
    Puppet.info("Mapping LUN '#{@resource[:name]}' to iGroup '#{@resource[:initiatorgroup]}'")
    lun_mapped_status = get_lun_mapped_status
    Puppet.debug("Current Lun mapping status after executing map operation - #{lun_mapped_status}")
    if  "#{lun_mapped_status}" == "false"
      exitvalue = lunmap(*get_create_command)
      Puppet.debug("Lun id assigned - #{exitvalue.child_get_int("lun-id-assigned")}")
      lun_mapped_status = get_lun_mapped_status
      if  "#{lun_mapped_status}" == "true"
        Puppet.info("LUN '#{@resource[:name]}' mapped to iGroup '#{@resource[:initiatorgroup]}' successfully")
      else
        raise Puppet::Error, "Failed to map LUN '#{@resource[:name]}' to iGroup '#{@resource[:initiatorgroup]}'"
      end
    else
      Puppet.info("LUN '@resource[:name]' already mapped to iGroup '#{@resource[:initiatorgroup]}'")
    end
  end

  def destroy
    Puppet.debug("Inside destroy method.")
    Puppet.info("UnMapping LUN '#{@resource[:name]}' from iGroup '#{@resource[:initiatorgroup]}'")
    lun_mapped_status = get_lun_mapped_status
    Puppet.debug("Current Lun mapping status after executing unmap operation - #{lun_mapped_status}")
    if  "#{lun_mapped_status}" == "true"
      lununmap(*get_destroy_command)
      lun_mapped_status = get_lun_mapped_status
      if  "#{lun_mapped_status}" == "false"
        Puppet.info("LUN '#{@resource[:name]}' unmapped from iGroup '#{@resource[:initiatorgroup]}' successfully")
      else
        raise Puppet::Error, "Failed to unmap the LUN '#{@resource[:name]}' from iGroup '#{@resource[:initiatorgroup]}'"
      end
    else
      Puppet.info("LUN '@resource[:name]' not mapped to iGroup '#{@resource[:initiatorgroup]}'")
    end
  end

  def exists?
    Puppet.debug("Inside exists method.")
    lun_mapped_status = get_lun_mapped_status
    if  "#{lun_mapped_status}" == "false"
      Puppet.debug("Lun mapping status before executing any map/unmap operation - #{lun_mapped_status}")
      false
    else
      Puppet.debug("Lun mapping status before executing any map/unmap operation - #{lun_mapped_status}")
      true
    end

  end

end

