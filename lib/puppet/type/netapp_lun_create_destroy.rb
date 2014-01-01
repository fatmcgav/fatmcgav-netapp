Puppet::Type.newtype(:netapp_lun_create_destroy) do
  @doc = "Manage Netapp LUN creation and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The Path of the LUN to be created."
  end

  newparam(:ostype) do
    desc "The os type for the LUN."
  end

  newparam(:size_bytes) do
    desc "The size for the LUN in bytes."
  end

  newparam(:space_res_enabled, :boolean => false) do
    desc "By default, the lun is space-reserved. If it is desired to manage space usage
             manually instead,this can be set to false which will create a LUN without
             any space being reserved"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:force, :boolean => false) do
    desc "Forcibly destroys the LUN, disabling mapping conflict checks with the high-availability partner."
    newvalues(:true, :false)
    defaultto :false
end
end
