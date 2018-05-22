# profile to deploy a puppet master

class profile::master {

  include ::firewall

  firewall { '8140 accept - puppetserver':
    dport  => '8140',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '8200 accept - vault':
    dport  => '8200',
    proto  => 'tcp',
    action => 'accept',
  }

  class { '::puppetserver':
    before  => Service['puppet'],
  }

  class{'::profile::vault_hiera_puppetserver':}

  file { '/etc/puppetlabs/puppet/autosign.conf':
    ensure  => 'file',
    content => '*',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['puppetserver'],
    notify  => Service['puppetserver'],
  }

  class { '::puppetdb':
    ssl_listen_address => '0.0.0.0',
    listen_address     => '0.0.0.0',
    open_listen_port   => true,
  }

  class { '::puppetdb::master::config':
    puppetdb_server         => 'puppet',
    strict_validation       => false,
    manage_report_processor => true,
    enable_reports          => true,
    # https://tickets.puppetlabs.com/browse/PDB-2591
    restart_puppet          => false,
  }

  include ::profile::vault_server

}
