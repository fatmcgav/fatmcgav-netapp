require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_lun).provide(:netapp_lun, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Lun creation, modification and deletion."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :luncreate      => 'lun-create-by-size'
  netapp_commands :lundestroy     => 'lun-destroy'
  netapp_commands :lunlist        => 'lun-list-info'

  mk_resource_methods
  def get_lun_existence_status

    lun_exists = 'false'
    Puppet.debug("Fetching Lun information")
    begin
      result = lunlist("path", @resource[:name])
      Puppet.debug(" Lun informations - #{result}")
    rescue

    end

    if (result != nil)
      lun_exists = 'true'
    end

    return lun_exists

  end

  def get_create_command
    arguments = ["path", @resource[:name], "size", @resource[:size_bytes]]

    if @resource[:space_res_enabled] == :true
      arguments +=["space-reservation-enabled", @resource[:space_res_enabled]]
    end

    if ((@resource[:ostype]!= nil) && (@resource[:ostype].length > 0))
      arguments +=["ostype", @resource[:ostype]]
    end

    return arguments
  end

  def get_destroy_command
    arguments = ["path", @resource[:name]]
    if @resource[:force] == :true
      arguments +=["force", @resource[:force] ]
    end

    return arguments
  end

  def create
    Puppet.debug("Inside create method.")
    Puppet.info("Creating LUN '#{@resource[:name]}'")
    exitvalue = luncreate(*get_create_command)
    #Puppet.debug("Current LUN size after executing create operation - #{exitvalue.child_get_int("actual-size")}")
    lun_exists = get_lun_existence_status
    Puppet.debug("Lun existence status after executing create operation - #{lun_exists}")
    if  "#{lun_exists}" == "true"
      Puppet.info("LUN '#{@resource[:name]}' created successfully.")
    else
      raise Puppet::Error, "Failed to create the LUN '@resource[:name]'"
    end
  end

  def destroy
    Puppet.debug("Inside destroy method.")
    Puppet.info("Destroying LUN '#{@resource[:name]}'")
    lundestroy(*get_destroy_command)
    lun_exists = get_lun_existence_status
    Puppet.debug("Lun existence status after executing destroy operation - #{lun_exists}")
    if  "#{lun_exists}" == "false"
      Puppet.info("Successfully destroyed the LUN '#{@resource[:name]}'")
    else
      #Puppet.info("Failed to destroy the LUN '@resource[:name]'")
      raise Puppet::Error, "Failed to destroy the LUN '#{@resource[:name]}'"
    end

  end

  def exists?
    Puppet.debug("Inside exists method.")
    lun_exists = get_lun_existence_status
    if  "#{lun_exists}" == "false"
      Puppet.debug("Lun existence status before executing any create/destroy operation - #{lun_exists}")
      Puppet.info("LUN '#{@resource[:name]}' does not exists")
      false
    else
      Puppet.debug("Lun existence status before executing any create/destroy operation - #{lun_exists}")
      Puppet.info("LUN '#{@resource[:name]}' already exists")
      true
    end
  end

end
