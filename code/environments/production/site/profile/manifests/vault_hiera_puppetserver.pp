# profile to deploy a puppet vault_server

class profile::vault_hiera_puppetserver {

  include ::puppetserver

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
  ->
  package { 'debouncer-puppetserver-gem':
    ensure   => 'present',
    name     => 'debouncer',
    provider => 'puppetserver_gem',
  }
  ->
  package { 'debouncer-puppetpath-gem':
    ensure   => 'present',
    name     => 'debouncer',
    provider => 'puppet_gem',
  }
  ~> Service['puppetserver']

}
