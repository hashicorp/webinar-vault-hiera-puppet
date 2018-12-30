# common class that gets applied to all nodes
# See: "code/environments/production/hieradata/common.yaml"
# It:
#  - configures /etc/hosts entries
#  - makes sure puppet is installed and running
#  - makes sure mcollective + client is installed and running
#
class profile::base {

  host { 'node1.vm':
    ensure       => 'present',
    host_aliases => ['node1'],
    ip           => '10.13.37.3',
    target       => '/etc/hosts',
  }

  host { 'puppet.vm':
    ensure       => 'present',
    host_aliases => ['puppet'],
    ip           => '10.13.37.2',
    target       => '/etc/hosts',
  }

  package { 'puppet-agent':
    ensure => installed,
  }

  service { 'puppet':
    ensure  => running,
    enable  => true,
    require => Package['puppet-agent'],
  }

}
