# profile to deploy a puppet vault_server

class profile::vault_server {

  package { 'unzip':
    ensure => installed,
    before => Class['::vault'],
  }

  file { '/mnt/vault/':
    ensure => directory,
    owner  => 'vault',
    group  => 'vault',
  }

  class { '::vault':
    manage_storage_dir => true,
    storage => {
      file => {
        path => '/mnt/vault/data',
      },
    },
    listener => {
      tcp => {
        address       => '0.0.0.0:8200',
        tls_disable   => 1,
      },
    },
    version   => '0.10.1',
    enable_ui => true,
  }

}
