# webinar-vault-hiera-puppet

> This is a sandbox repository to show how HashiCorp's Vault can be used to interact with Hiera for the storage of secrets in a Puppet environment.

It accompanies the webinar that was presented on May 23rd 2018: [Webinar](https://www.hashicorp.com/resources/hashicorp-vault-with-puppet-hiera-5-for-secret-management)

In the Vagrantfile there are 2 VMs defined:

A puppetserver ("puppet") and a puppet node ("node1") both running CentOS 7.0.

Classes get configured via hiera (see `code/environments/production/hieradata/*`).

# Requirements and Setup

* Vagrant 2.X (Works with older but easier to use newer!)
* VirtualBox
* The puppetserver VM is configured to use 3GB of RAM
* The node is using the default (usually 512MB).
* A shell provisioner ("install_puppet.sh") which installs the Puppet 6 Yum repos and updates `puppet-agent` before running it for the first time. That way newly spawned Vagrant environments will always use the latest available version.
* There is no DNS server running in the private network, sll nodes have each other in their `/etc/hosts` files.

# Usage

After cloning the repository make sure the submodules are also updated:

```
$ git clone https://github.com/hashicorp/webinar-vault-hiera-puppet
$ cd webinar-vault-hiera-puppet
$ git submodule update --init --recursive
```

Whenever you `git pull` this repository you should also update the submodules again.

Now you can simply run `vagrant up puppetserver` to get a fully set up puppetserver.

The `code/` folder will be a synced folder and gets mounted to `/etc/puppetlabs/code` inside the VM.

If you want to attach a node to the puppetserver simply run `vagrant up node1`.
Once provisioned it is automatically connecting to the puppetserver and it gets automatically signed.

After that puppet will run automatically every 30 minutes on the node and apply your changes.

You can also run it manually:

```
$ vagrant ssh node1
[vagrant@node1 ~]$ sudo /opt/puppetlabs/bin/puppet agent -t
Info: Caching certificate for node1
Info: Caching certificate_revocation_list for ca
Info: Caching certificate for node1
Info: Retrieving pluginfacts
Info: Retrieving plugin
(...)
Notice: Applied catalog in 0.52 seconds
```

# Configuring Vault

Vault gets installed and started by default on the Puppetserver node.

The local port 8200 gets forwarded to the Vagrant VM to port 8200.

Vault is initalized as part of a bootstrap process:

```ruby
$vault_init_unseal = <<-SCRIPT
export VAULT_ADDR=http://localhost:8200
/usr/local/bin/vault operator init -key-shares=1 -key-threshold=1 | tee vault.keys
VAULT_TOKEN=$(grep '^Initial' vault.keys | awk '{print $4}')
VAULT_KEY=$(grep '^Unseal Key 1:' vault.keys | awk '{print $4}')
export VAULT_TOKEN
/usr/local/bin/vault operator unseal "$VAULT_KEY"
echo $VAULT_TOKEN > /etc/vault_token.txt
SCRIPT
```

So the token saved to `/etc/vault_token.txt` which is read by `hiera_vault`.

Now, run an agent run on your node1 node:

```
$ vagrant ssh node1 --command "sudo puppet agent -t"
Info: Using configured environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Retrieving locales
Info: Loading facts
Info: Caching catalog for node1.home
Info: Applying configuration version '1521467005'
Notice: testing vault hello_123
Notice: /Stage[main]/Profile::Vault_message/Notify[testing vault hello_123]/message: defined 'message' as 'testing vault hello_123'
Notice: Applied catalog in 0.14 seconds
[root@node1 vagrant]# exit
```

Now we can change that value!

Log onto the `puppet` with `vagrant ssh puppet`, and change the secret contents:

```
$ export VAULT_ADDR=http://127.0.0.1:8200
$ export VAULT_TOKEN=$(cat /etc/vault_token.txt)
$ export PATH=$PATH:/usr/local/bin/
$ vault secrets enable -version=1 -path=puppet kv
$ vault kv put puppet/node1.vm/vault_notify value=hello345
Success! Data written to: puppet/node1.vm/vault_notify
```

And see the message change:

```
Info: Using configured environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Retrieving locales
Info: Loading facts
Info: Caching catalog for node1.vm
Info: Applying configuration version '1545176860'
Notice: testing vault hello345
Notice: /Stage[main]/Profile::Vault_message/Notify[testing vault hello345]/message: defined 'message' as 'testing vault hello345'
Notice: Applied catalog in 0.18 seconds
```

You can also do this from your host:
```
$ vagrant provision node1 --provision-with puppet_server
==> node1: Running provisioner: puppet_server...
==> node1: Running Puppet agent...
==> node1: Info: Using configured environment 'production'
==> node1: Info: Retrieving pluginfacts
==> node1: Info: Retrieving plugin
==> node1: Info: Retrieving locales
==> node1: Info: Loading facts
==> node1: Info: Caching catalog for node1.home
==> node1: Info: Applying configuration version '1545176861'
==> node1: Notice: testing vault hello_123
==> node1: Notice: /Stage[main]/Profile::Vault_message/Notify[testing vault hello_123]/message: defined 'message' as 'testing vault hello345'
==> node1: Notice: Applied catalog in 0.16 seconds
```

# Security

This repository is meant as a non-production sandbox setup.
It is not a guide on how to setup a secure Puppet and Vault environment.

In particular this means:

* Auto signing is enabled, every node that connects to the puppetserver is automatically signed.
* Passwords or PSKs are not randomized and easily guessable.
* Vault should be on it's own dedicated node rather than the same server as the puppet master
* Vault is being initialzed and unsealed automatically and the root token saved to a file on disk, this should be a manual step or use Vault Cloud Autounseal

For a non publicly reachable playground this should be acceptable.
