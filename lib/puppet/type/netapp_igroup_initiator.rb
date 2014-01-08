Puppet::Type.newtype(:netapp_igroup_initiator) do
  @doc = "Manage Netapp iGroup add and remove."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "Name of iGroup"
  end

  newparam(:initiator) do
    desc "This defines the WWPN or Alias of Initiator"
  end

  newparam(:force, :boolean => false) do
    desc "This parameter if set to true forcibly add the initiator, disabling mapping
    and type conflict checks with the high-availability partner. If not specified all
    conflict checks are performed"
    newvalues(:true, :false)
    defaultto :false
  end

end

