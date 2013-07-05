Puppet::Type.newtype(:netapp_quota) do
  @doc = "Manage NetApp quota entries.  Please note that NetApp identifies
    a quota entry uniquely by the type, target, volume, and qtree. This type
    on the other hand has to uniquely identify a quota entry only by its
    target.  This means that you cannot manage two quota entries for the
    same user (username = quota-target) but for different trees. As a result
    this type is best at managing tree quotas

    Example:

    Limit `qtree1` on `vol1` to 10G

        netapp_quota { '/vol/vol1/qtree1':
          ensure    => present,
          type      => tree,
          volume    => 'vol1',
          disklimit => '10G',
        }

     Limit user bob to consume 2G on qtree1. Note that you cannot
     define multiple quotas for user bob:

         netapp_quota { 'bob':
           ensure    => present,
           type      => user,
           qtree     => 'qtree1',
           volume    => 'vol1',
           disklimit => '2048M',
         }

     Make sure the following restrictions apply in your
     environment before using this type:
     - every quota target has to be unique
     - quota entries must not contain any special characters that would
       require quotation"

  apply_to_device

  ensurable

  class NetAppQuotaLimitProperty < Puppet::Property

    self::UNIT_BASE = {
      ''  => 0,
      'K' => 10,
      'M' => 20,
      'G' => 30,
      'T' => 40,
    }

    def is_to_s(current_value = @is)
      return current_value if current_value == :absent
      ['T', 'G', 'M', 'K'].each do |unit|
        if current_value % (1 << self::class::UNIT_BASE[unit]) == 0
          return "#{current_value >> self::class::UNIT_BASE[unit]}#{unit}"
        end
      end
      current_value.to_s
    end

    def should_to_s(desired_value = @should)
      return desired_value if desired_value == :absent
      ['T', 'G', 'M', 'K'].each do |unit|
        if desired_value % (1 << self::class::UNIT_BASE[unit]) == 0
          return "#{desired_value >> self::class::UNIT_BASE[unit]}#{unit}"
        end
      end
      desired_value.to_s
    end

    munge do |value|
      if value == :absent or value == "absent"
        :absent
      elsif match = /^([0-9]+)([KMGT])?$/.match(value.to_s)
        normalized = match.captures[0].to_i
        if unit = match.captures[1]
          normalized <<= UNIT_BASE[unit]
        end
        normalized
      else
        raise Puppet::Error, "#{value} is not a valid size"
      end
    end
  end

  newparam(:name) do
    desc "The name of the quota target.  Depending on the quota type this
      can be a pathname (e.g. `/vol/vol1/qtree1`), a username, or a group"
    isnamevar
  end

  newproperty(:qtree) do
    desc "The qtree that the quota resides on. This is only relevant for
      `user` and `group` quotas"
  end

  newproperty(:type) do
    desc "The type of the quota. You can define `tree`, `user` or `group`
      here"

    newvalues :tree, :user, :group
  end

  newproperty(:disklimit, :parent => NetAppQuotaLimitProperty) do
    desc "The amount of space that the target can consume, e.g. `100M`
      or `2G`. You can also specify absent to make sure there is no limit."

    newvalues :absent, /^[0-9]+[KMGT]$/i
  end

  newproperty(:softdisklimit, :parent => NetAppQuotaLimitProperty) do
    desc "The amount of space the target has to consume before a message is
      logged. You can also specify absent to make sure there is no limit."

    newvalues :absent, /^[0-9]+[KMGT]$/i
  end


  newproperty(:filelimit, :parent => NetAppQuotaLimitProperty) do
    desc "The number of files that the target can have. You can also specify
      absent to make sure there is no limit."

    newvalues :absent, /^[0-9]+[KMGT]?$/i
  end

  newproperty(:softfilelimit, :parent => NetAppQuotaLimitProperty) do
    desc "The number of files the target has to own before a message is
      logged. You can also specify absent to make sure there is no limit"

    newvalues :absent, /^[0-9]+[KMGT]?$/i
  end

  newproperty(:threshold, :parent => NetAppQuotaLimitProperty) do
    desc "The amount of disk space the target has to consume before a message
      is logged. Set to absent to make sure the treshold is unlimited"

    newvalues :absent, /^[0-9]+[KMGT]$/i
  end

  newproperty(:volume) do
    desc "The name of the volume the quota resides on"

    newvalues /^\w+$/
  end

  validate do
    if self[:qtree] and type = self[:type] and type == :tree
      raise Puppet::Error, "Specifying qtree is invalid for tree type quotas"
    end
  end
end
