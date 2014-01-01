Puppet::Type.newtype(:netapp_lun_map_unmap) do
  @doc = "Manage map and unmap of LUNs to an iGroup."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The Path of the LUN to be mapped/unmapped."
  end

  newparam(:force, :boolean => true) do
    desc "Forcibly online the lun, disabling mapping conflict checks with the high-availability partner."
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:initiatorgroup) do
    desc "The name of the initiator group to which the given LUN has to be mapped/unmapped"
  end

end

