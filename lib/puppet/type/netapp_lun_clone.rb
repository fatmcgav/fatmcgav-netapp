Puppet::Type.newtype(:netapp_lun_clone) do
  @doc = "Manage Netapp Lun clone and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The Path of the LUN to be created after cloning"
  end

  newparam(:parentlunpath) do
    desc "The path of original/parent LUN"
  end

  newparam(:parentsnap) do
    desc "The LUN path of the backing snapshot"
  end

  newparam(:spacereservationenabled, :boolean => false) do
    desc "By default, the lun is space-reserved. If it is desired to manage
    space usage manually instead,this can be set to false which will create a LUN without
    any space being reserved"
    newvalues(:true, :false)
    defaultto :false
  end

end

