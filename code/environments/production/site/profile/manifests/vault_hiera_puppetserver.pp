# profile to deploy a puppet vault_server

class profile::vault_hiera_puppetserver {

  include ::puppetserver

  ini_setting { "Change jruby to 9k":
    ensure  => present,
    setting => 'JRUBY_JAR',
    path    => "/etc/sysconfig/puppetserver",
    key_val_separator => '=',
    section => '',
    value   => '"/opt/puppetlabs/server/apps/puppetserver/jruby-9k.jar"',
    show_diff => true,
    notify  => Class['puppetserver::service']
  }
  ->
  package { 'vault-puppetserver-gem':
    ensure   => 'present',
    name     => 'vault',
    provider => 'puppetserver_gem',
  }
  ->
  package { 'vault-puppetpath-gem':
    ensure   => 'present',
    name     => 'vault',
    provider => 'puppet_gem',
  }

}
