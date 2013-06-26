# == Define: netapp::vqe
#
# Utility class for creation of a NetApp Volume, Qtree and NFS export.
#
# === Parameters:
#
# [*ensure*]
#   The resource state.
#
# [*size*]
#   The volume size to create/set.
#
# [*aggr*]
#   The aggregate to contain the volume.
#
# [*spaceres*]
#   Space reservation mode. Valid options are: none, file and volume.
#
# [*snapresv*]
#   The amount of space to reserve for snapshots, in percent.
#
# [*autoincrement*]
#   Should the volume auto-increment? True/False.
#
# [*options*]
#   Hash of options to set on volume. Keyshould match option name.
#
# [*snapschedule*]
#   Hash of snapschedule to set on volume.
#
# [*persistent*]
#   Should the export be persistent? True/False.
#
# === Actions:
#
# === Requires:
#
# === Sample Usage:
#
# Make sure there is a volume called `v_test_volume`, a qtree
# called `q_test_volume` and there is an NFS Export. The initial
# size will be 1 TeraByte.
#
#     netapp::vqe { 'test_volume':
#       size           => "1t",
#       aggr           => "aggr1",
#       spaceres       => "file",
#       snapresv       => 20,
#       autoincrement  => false,
#       persistent     => false
#     }
#
#
define netapp::vqe (
  $size,
  $ensure        = 'present',
  $aggr          = 'aggr1',
  $spaceres      = 'none',
  $snapresv      = 0,
  $autoincrement = true,
  $options       = {
    'convert_ucode'   => 'on',
    'no_atime_update' => 'on',
    'try_first'       => 'volume_grow'
  },
  $snapschedule  = {
    'minutes'       => 0,
    'hours'         => 0,
    'days'          => 0,
    'weeks'         => 0,
    'which-hours'   => 0,
    'which-minutes' => 0
  },
  $persistent = true
) {


  netapp_volume { "v_${name}":
    ensure        => $ensure,
    initsize      => $size,
    aggregate     => $aggr,
    spaceres      => $spaceres,
    snapreserve   => $snapresv,
    autoincrement => $autoincrement,
    options       => $options,
    snapschedule  => $snapschedule,
  }

  netapp_qtree { "q_${name}":
    ensure => $ensure,
    volume => "v_${name}",
  }

  netapp_export { "/vol/v_${name}/q_${name}":
    ensure     => $ensure,
    persistent => $persistent,
  }

  if $ensure == 'absent' {
    Netapp_export["/vol/v_${name}/q_${name}"]
      -> Netapp_qtree["q_${name}"] ->
      -> Netapp_volume["v_${name}"]
  }
  else {
    Netapp_volume["v_${name}"]
      -> Netapp_qtree["q_${name}"]
      -> Netapp_export["/vol/v_${name}/q_${name}"]
  }
}
