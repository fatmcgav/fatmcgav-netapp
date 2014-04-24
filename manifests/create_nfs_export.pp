define netapp::create_nfs_export (
  $size,
  $ensure        = 'present',
  $aggr          = 'aggr1',
  $spaceres      = 'none',
  $snapresv      = 0,
  $autoincrement = true,
  $snapschedule  = {
    'minutes'       => 0,
    'hours'         => 0,
    'days'          => 0,
    'weeks'         => 0,
    'which-hours'   => 0,
    'which-minutes' => 0
  },
  $options       = {
    'convert_ucode'   => 'on',
    'no_atime_update' => 'on',
    'try_first'       => 'volume_grow'
  },
  $persistent = true ,
  $readonly = '',
  $readwrite = ['all_hosts'] ,
  $append_readwrite = true
  ) {

  netapp_volume { "${name}":
    ensure        => $ensure,
    initsize      => $size,
    aggregate     => $aggr,
    spaceres      => $spaceres,
    snapreserve   => $snapresv,
    autoincrement => $autoincrement,
    options       => $options,
    snapschedule  => $snapschedule,
  }
  
  netapp_export { "/vol/${name}":
      ensure   => $ensure,
      persistent => $persistent,
      readonly => $readonly,
      readwrite => $readwrite,
      append_readwrite => $append_readwrite
  }
 
}

