# Define: netapp::volume
#
# Utility class for NetApp Volume configuration. 
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# 
define netapp::volume (
        $ensure = present,
        $size,
        $aggr = 'aggr1',
        $snapresv = 0,
        $autoincrement = true,
        $options = {'convert_ucode' => 'on', 'no_atime_update' => 'on', 'try_first' => 'volume_grow'},
        $snapschedule = {"minutes" => 0, "hours" => 0, "days" => 0, "weeks" => 0, "which-hours" => 0, "which-minutes" => 0}
        ) {

        netapp_volume { "v_${name}":
                ensure => $ensure,
                initsize => $size,
                aggregate => $aggr,
                spaceres => "none",
                snapreserve => $snapresv,
                autoincrement => $autoincrement,
                options => $options,
                snapschedule => $snapschedule
        }
        ->
        netapp_qtree { "q_${name}":
                ensure => $ensure,
                volume => "v_${name}"
        }
        ->
        netapp_export { "/vol/v_${name}/q_${name}":
                ensure => $ensure,
                persistent => true
        }

}
