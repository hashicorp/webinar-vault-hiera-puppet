if !Dir.exist?("#{__dir__}/code/environments/production/modules/puppetserver/")
  puts "You need to initialize submodules first!"
  puts "Run: `git submodule update --init --recursive` in the root of the repo"
  exit 1
end

Vagrant.configure(2) do |config|

  config.vm.define "puppetserver", primary: true do |puppetserver|
    puppetserver.vm.hostname = "puppet.vm"
    puppetserver.vm.box = "bento/centos-7"
    puppetserver.vm.network "private_network", ip: "10.13.37.2"
    puppetserver.vm.network :forwarded_port, guest: 8200, host: 8200, id: "vault"

    puppetserver.vm.synced_folder "code", "/etc/puppetlabs/code"

    puppetserver.vm.provider :virtualbox do |vb|
      vb.memory = "3072"
    end

    puppetserver.vm.provision "shell", path: "install_puppet.sh"

$puppet_boostrap = <<-SCRIPT
puppet apply -e 'include ::role::master' --modulepath=/etc/puppetlabs/code/environments/production/modules/:/etc/puppetlabs/code/environments/production/site/ --environment=puppetserver_vault_bootstrap
SCRIPT

$vault_init_unseal = <<-SCRIPT
export VAULT_ADDR=http://localhost:8200
/usr/local/bin/vault operator init -key-shares=1 -key-threshold=1 | tee vault.keys
VAULT_TOKEN=$(grep '^Initial' vault.keys | awk '{print $4}')
VAULT_KEY=$(grep '^Unseal Key 1:' vault.keys | awk '{print $4}')
export VAULT_TOKEN
/usr/local/bin/vault operator unseal "$VAULT_KEY"
echo $VAULT_TOKEN > /etc/vault_token.txt
SCRIPT

    puppetserver.vm.provision "shell", inline: $puppet_boostrap
    puppetserver.vm.provision "shell", inline: $vault_init_unseal
  end

  config.vm.define "node1", primary: true do |node1|
    node1.vm.hostname = "node1.vm"
    node1.vm.box = "bento/centos-7"
    node1.vm.network "private_network", ip: "10.13.37.3"

    node1.vm.provision "shell", path: "install_puppet.sh"
  end

end
