# Configuracion clientes NTP

node default {
  class { 'ntp':
        servers => ['2001:470:0:50::2','2001:470:0:2c8::2']
  }
}
