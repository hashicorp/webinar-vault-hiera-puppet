if !Dir.exist?("#{__dir__}/code/environments/production/modules/puppetserver/")
  puts "You need to initialize submodules first!"
  puts "Run: `git submodule update --init --recursive` in the root of the repo"
  exit 1
end

Vagrant.configure(2) do |config|

  $install_puppet_script = <<-INSTALL_SCRIPT
wget -O - https://raw.githubusercontent.com/petems/puppet-install-shell/master/install_puppet_5_agent.sh | sudo sh
INSTALL_SCRIPT

$config_vault_script = <<-CONFIG_VAULT_SCRIPT
sudo /opt/puppetlabs/bin/puppet apply -e 'include ::role::master' --modulepath=/etc/puppetlabs/code/environments/production/modules/:/etc/puppetlabs/code/environments/production/site/ --environment=puppetserver_vault_bootstrap
CONFIG_VAULT_SCRIPT

  config.vm.define "puppetserver", primary: true do |puppetserver|
    puppetserver.vm.hostname = "puppet"
    puppetserver.vm.box = "geerlingguy/centos7"
    puppetserver.vm.box_version = "1.2.6"
    puppetserver.vm.network "private_network", ip: "10.13.37.2"
    puppetserver.vm.network :forwarded_port, guest: 8200, host: 8200, id: "vault"

    puppetserver.vm.synced_folder "code", "/etc/puppetlabs/code"

    puppetserver.vm.provider :virtualbox do |vb|
      vb.memory = "3072"
    end

    puppetserver.vm.provision "shell", path: "initial_bootstrap.sh"

    puppetserver.vm.provision "shell", inline: $config_vault_script

    puppetserver.vm.post_up_message = "Puppetserver has been bootstrapped! Please unseal Vault to continue the demo: \n `VAULT_ADDR='http://127.0.0.1:8200' vault operator init` then \n`VAULT_ADDR='http://127.0.0.1:8200' vault operator unseal`"

  end

  config.vm.define "node1", primary: true do |node1|
    node1.vm.hostname = "node1"
    node1.vm.box = "geerlingguy/centos7"
    node1.vm.box_version = "1.2.6"
    node1.vm.network "private_network", ip: "10.13.37.3"

    node1.vm.provision "shell", path: "initial_bootstrap.sh"
  end

end
