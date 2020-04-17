# Configuracion clientes DNS

$nameservers = ['2001:470:736b:7ff::2']

file { '/etc/resolv.conf':
  ensure => file,
  owner => 'a757024',
  group => 'a757024',
  mode => '0644',
  content => template('/home/a757024/resolv.conf.erb')
}
