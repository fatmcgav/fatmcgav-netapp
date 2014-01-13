require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_lun_clone).provide(:netapp_lun_clone, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Lun clone and deletion."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :luncreateclone  => 'lun-create-clone'
  netapp_commands :lundestroy      => 'lun-destroy'
  netapp_commands :lunlist         => 'lun-list-info'

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
    arguments = ["parent-lun-path", @resource[:parentlunpath], "path", @resource[:name], "parent-snap", @resource[:parentsnap]]
    if @resource[:spacereservationenabled] == :true
      arguments +=["space-reservation-enabled", @resource[:spacereservationenabled] ]
    end

    return arguments
  end

  def get_destroy_command
    arguments = ["path", @resource[:name]]
    return arguments
  end

  def create
    Puppet.debug("Inside create method.")
    Puppet.info("Creating LUN '#{@resource[:name]}' from parent LUN '#{@resource[:parentlunpath]}'")
    luncreateclone(*get_create_command)
    lun_exists = get_lun_existence_status
    if  "#{lun_exists}" == "true"
      Puppet.info("LUN '#{@resource[:name]}' created successfully.")
    else
      raise Puppet::Error, "Failed to clone the LUN '@resource[:name]'"
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
      Puppet.debug("Lun existence status before executing clone/destroy operation - #{lun_exists}")
      Puppet.info("LUN '#{@resource[:name]}' does not exists")
      false
    else
      Puppet.debug("Lun existence status before executing clone/destroy operation - #{lun_exists}")
      Puppet.info("LUN '#{@resource[:name]}' already exists")
      true
    end
  end
end
