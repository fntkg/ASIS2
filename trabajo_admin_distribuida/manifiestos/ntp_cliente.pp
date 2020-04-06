# Configuracion clientes NTP

node default {
  class { 'ntp':
        servers => ['2001:470:736b:7ff::2']
  }
}
