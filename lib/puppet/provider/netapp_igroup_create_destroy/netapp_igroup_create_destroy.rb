require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_igroup_create_destroy).provide(:netapp_igroup_create_destroy, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp iGroup create/destroy operations."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :igrouplist     => 'igroup-list-info'
  netapp_commands :igroupcreate   => 'igroup-create'
  netapp_commands :igroupdestroy  => 'igroup-destroy'
  def get_igroup_status
    igroup_status = 'false'
    Puppet.debug("Fetching iGroup information")
    begin
      result = igrouplist("initiator-group-name", @resource[:name])
      Puppet.debug(" iGroup informations - #{result}")
    rescue
    end
    if (result != nil)
      igroup_status = 'true'
    end
    return igroup_status
  end

  def get_create_command
    arguments = ["initiator-group-name", @resource[:name], "initiator-group-type", @resource[:initiatorgrouptype]]

    if ((@resource[:ostype]!= nil) && (@resource[:ostype].length > 0))
      arguments +=["os-type", @resource[:ostype]]
    end
    return arguments
  end

  def get_destroy_command
    arguments = ["initiator-group-name", @resource[:name]]
    if @resource[:force] == :true
      arguments +=["force", @resource[:force]]
    end
    return arguments
  end

  def create
    Puppet.debug("Inside create method.")
    Puppet.info("Creating iGroup '#{@resource[:name]}'")
    igroup_status = get_igroup_status
    if  "#{igroup_status}" == "false"
      Puppet.debug("iGroup existence status before executing create operation - #{igroup_status}")
      igroupcreate(*get_create_command)
      igroup_status = get_igroup_status
      Puppet.debug("iGroup existence status after executing create operation - #{igroup_status}")
      if  "#{igroup_status}" == "true"
       
        Puppet.info("iGroup '#{@resource[:name]}' created successfully")
      else
        raise Puppet::Error, "Failed to create the iGroup '#{@resource[:name]}'"
      end
    else
      Puppet.info("iGroup '#{@resource[:name]}' already exists.")
    end
  end

  def destroy
    Puppet.debug("Inside destroy method.")
    Puppet.info("Destroying iGroup '#{@resource[:name]}'")
    igroup_status = get_igroup_status
    Puppet.debug("iGroup existence status after executing destroy operation - #{igroup_status}")
    if  "#{igroup_status}" == "true"
      igroupdestroy(*get_destroy_command)
      igroup_status = get_igroup_status
      if  "#{igroup_status}" == "false"
        Puppet.info("iGroup '#{@resource[:name]}' destroyed successfully")
      else
        raise Puppet::Error, "Failed to destroy the iGroup '#{@resource[:name]}'"
      end
    else
      Puppet.info("iGroup '@resource[:name]' does not exists")
    end
  end

  def exists?
    Puppet.debug("Inside exists method.")
    igroup_status = get_igroup_status
    if  "#{igroup_status}" == "false"
      Puppet.debug("iGroup existence status before executing any create/destroy operation - #{igroup_status}")
      Puppet.info("iGroup '#{@resource[:name]}' does not exists")
      false
    else
      Puppet.debug("iGroup existence status before executing any create/destroy operation - #{igroup_status}")
      Puppet.info("iGroup '#{@resource[:name]}' already exists")
      true
    end
  end

end

