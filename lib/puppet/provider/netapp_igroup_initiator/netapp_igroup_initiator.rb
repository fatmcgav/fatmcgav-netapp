require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_igroup_initiator).provide(:netapp_igroup_initiator, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp iGroup initiator add/remove operations."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :igrouplist     => 'igroup-list-info'
  netapp_commands :igroupadd      => 'igroup-add'
  netapp_commands :igroupremove   => 'igroup-remove'
  def get_igroup_initiator_status

    igroup_initiator_status = 'false'
    Puppet.debug("Fetching iGroup information")
    begin
      result = igrouplist("initiator-group-name", @resource[:name])
      Puppet.debug(" iGroup initiator informations - #{result}")
    rescue

    end

    if(result != nil)
      initiator_groups = result.child_get("initiator-groups")
      initiator_group_info = initiator_groups.children_get()

      # Itterate through the luns-clone_lists_info blocks
      initiator_group_info.each do |initiatorinfo|
        # Pull out relevant info
        initiators = initiatorinfo.child_get("initiators")
        initiator_info = initiators.children_get()

        initiator_info.each do |initiator|
          value = initiator.child_get_string("initiator-name")
          if ((value != nil) && (@resource[:initiator] == value))
            igroup_initiator_status = 'true'
          end
        end
      end
    end

    return igroup_initiator_status

  end

  def get_create_command
    arguments = ["initiator-group-name", @resource[:name], "initiator", @resource[:initiator]]
    if @resource[:force] == :true
      arguments +=["force", @resource[:force] ]
    end

    return arguments
  end

  def get_destroy_command
    arguments = ["initiator-group-name", @resource[:name], "initiator", @resource[:initiator]]
    if @resource[:force] == :true
      arguments +=["force", @resource[:force] ]
    end

    return arguments
  end

  def create
    Puppet.debug("Inside create method.")
    Puppet.info("Adding initiator '#{@resource[:initiator]}' to iGroup '#{@resource[:name]}'")
    igroup_initiator_status = get_igroup_initiator_status
    Puppet.debug("iGroup initiator status after executing add operation - #{igroup_initiator_status}")
    if  "#{igroup_initiator_status}" == "false"
      igroupadd(*get_create_command)
      igroup_initiator_status = get_igroup_initiator_status
      if  "#{igroup_initiator_status}" == "true"
        Puppet.info("Initiator '#{@resource[:initiator]}' added successfully to iGroup '#{@resource[:name]}'")
      else
        raise Puppet::Error, "Failed to add initiator '#{@resource[:initiator]}' to iGroup '#{@resource[:name]}'"
      end
    else
      Puppet.info("Initiator '#{@resource[:initiator]}' already exists in iGroup '#{@resource[:name]}'")
    end
  end

  def destroy
    Puppet.debug("Inside destroy method.")
    Puppet.info("Removing initiator '#{@resource[:initiator]}' from iGroup '#{@resource[:name]}'")
    igroup_initiator_status = get_igroup_initiator_status
    if  "#{igroup_initiator_status}" == "true"
      igroupremove(*get_destroy_command)
      igroup_initiator_status = get_igroup_initiator_status
      if  "#{igroup_initiator_status}" == "false"
        Puppet.info("Initiator '#{@resource[:initiator]}' removed successfully from iGroup '#{@resource[:name]}'")
      else
        raise Puppet::Error, "Failed to remove initiator '#{@resource[:initiator]}' from iGroup '#{@resource[:name]}'"
      end
    else
      Puppet.info("Initiator '#{@resource[:initiator]}' does not exists in iGroup '#{@resource[:name]}'")
    end

  end

  def exists?
    Puppet.debug("Inside exists method.")
    igroup_initiator_status = get_igroup_initiator_status
    if  "#{igroup_initiator_status}" == "false"
      Puppet.debug("iGroup initiator status before executing any add/remove operation - #{igroup_initiator_status}")
      Puppet.info("Initiator '#{@resource[:initiator]}' does not exists in iGroup '#{@resource[:name]}'")
      false
    else
      Puppet.debug("iGroup initiator status before executing any add/remove operation - #{igroup_initiator_status}")
      Puppet.info("Initiator '#{@resource[:initiator]}' already exists in iGroup '#{@resource[:name]}'")
      true
    end
  end

end

