Puppet::Type.newtype(:netapp_nfs) do
	@doc = "Manage Netapp NFS exports"

	apply_to_device

	ensurable do
		desc "netapp export resource state. Valid values are present, absent"

		defaultto(:present)

		newvalue(:present) do
			provider.create
		end

		newvalue(:absent) do
			provider.destroy
		end
	end

	newparam(:path, :namevar=>true) do
		desc "The export path."
	end

	newproperty(:definition) do
		desc "The export definition"
	end
end