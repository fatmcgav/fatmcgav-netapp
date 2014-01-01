Puppet::Type.newtype(:netapp_lun_online_offline) do
  @doc = "Manage Netapp Lun online and offline."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The Path of the LUN."
  end

  newparam(:force, :boolean => false) do
    desc "Forcibly online the lun, disabling mapping conflict checks with the high-availability partner."
    newvalues(:true, :false)
    defaultto :false
  end

end

