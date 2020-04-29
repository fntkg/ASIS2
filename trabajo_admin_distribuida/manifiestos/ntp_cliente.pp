# Configuracion clientes NTP

$string = "server 2001:470:736b:7ff::2"

case $operatingsystem {
        openbsd: {
                $service = 'ntpd'
                $file = '/etc/ntpd.conf'
        }
        ubuntu: {
                $service = 'npt'
                $file = '/etc/ntp.conf'
         }
}

file { $file:
        ensure => file,
        content => $string
}

service { $service:
        ensure => running,
        enable => true,
        subscribe => File[$file]
}
