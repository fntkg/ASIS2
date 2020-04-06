# Configuracion clientes DNS

$nameservers = ['2001:470:736b:7ff::2']

file { '/etc/resolv.conf':
  ensure => file,
  owner => 'root',
  group => 'root',
  mode => '0644',
  content => template('resolv.conf.erb')
}
