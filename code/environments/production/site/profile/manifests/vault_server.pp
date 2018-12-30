# profile to deploy a puppet vault_server

class profile::vault_server {

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
    version   => '1.0.1',
    enable_ui => true,
  }

}
