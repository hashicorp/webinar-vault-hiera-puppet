# webinar-vault-hiera-puppet

> This is a sandbox repository to show how HashiCorp's Vault can be used to interact with Hiera for the storage of secrets in a Puppet environment.

It accompanies the webinar that was presented on May 23rd 2018: LINK TO WEBINAR

In the Vagrantfile there are 2 VMs defined:

A `puppetserver` node ("puppet") and a puppet node ("node1") both running CentOS 7

Classes get configured via hiera (see `code/environments/production/hieradata/*`).

# Requirements and Setup

* Vagrant 2.X (Works with older but easier to use newer!)
* VirtualBox
* The puppetserver VM is configured to use 3GB of RAM
* The node is using the default (usually 512MB).
* There is no DNS server running in the private network, sll nodes have each other in their `/etc/hosts` files manually

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

From there, you will need to initialize and unseal Vault, as it's required for the `puppet agent` compile runs

## Configuring Vault

Vault gets installed and started by default on the Puppetserver node.

The local port 8200 gets forwarded to the Vagrant VM to port 8200.

To initialise vault, first do an export of the vault address:

```
export VAULT_ADDR='http://127.0.0.1:8200'
```

Then perform an initilization

```
$ vault operator init

Unseal Key 1: qduQtx3VNgLN/9WP1ZRzCq1ZB709DZ3TS/D52YS6yLzr
Unseal Key 2: YSXO2hST8+FHoBrn1SgI6yn+ApriQpqiDKhrnLXH9ojP
Unseal Key 3: o+Og63B2/cJiX/8VoshTlBIb/dkCoeGrgSv2bPLQzBjE
Unseal Key 4: lfNiq0/B5V1IXyKzivjDRXqetHtcXqaHj8prF9RclL08
Unseal Key 5: DL3Xf4FSxIv6+NEYdZCZaskf0jcJ0bowe34r7Gdl7Y+9
Initial Root Token: 677b88e3-300c-3a5a-ea2f-72ba70be5516

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your vault will remain permanently sealed.
```

Unseal Vault using the unseal keys:

```
$ vault unseal
Key (will be hidden):
```

## Creating a token from a policy created by Terraform

You could then use the root token as the key that Hiera uses, but this is a little over the top and would allow far too much access.

Instead, lets create a policy with Terraform, then create a token that uses that policy that's locked to only use the Puppet secret endpoint.

Change directory to the terraform folder:

```
cd terraform/`
```

Then, export your root token as an environment variable:

```
export VAULT_TOKEN=677b88e3-300c-3a5a-ea2f-72ba70be5516
```

Now run a an apply to create the policy and add an example secret:

```
$ terraform init
$ terraform apply
vault_generic_secret.vault_notify: Refreshing state... (ID: secret/puppet/node1/vault_notify)
vault_policy.hiera_vault: Refreshing state... (ID: hiera)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  + vault_generic_secret.vault_notify
      id:           <computed>
      data_json:    "{\"value\":\"Hello World\"}"
      disable_read: "false"
      path:         "secret/puppet/node1/vault_notify"

  ~ vault_policy.hiera_vault
      policy:       "" => "path \"secret/puppet/*\" {\n  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]\n}\n"


Plan: 1 to add, 1 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

vault_generic_secret.vault_notify: Creating...
  data_json:    "" => "{\"value\":\"Hello World\"}"
  disable_read: "" => "false"
  path:         "" => "secret/puppet/node1/vault_notify"
vault_policy.hiera_vault: Modifying... (ID: hiera)
  policy: "" => "path \"secret/puppet/*\" {\n  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]\n}\n"
vault_generic_secret.vault_notify: Creation complete after 0s (ID: secret/puppet/node1/vault_notify)
vault_policy.hiera_vault: Modifications complete after 0s (ID: hiera)

Apply complete! Resources: 1 added, 1 changed, 0 destroyed.
```

Then, create a token using the Puppet policy you just created:

```
$ vault token create -policy=hiera
Key                Value
---                -----
token              4d82fbc8-1e50-ee43-5cbb-38715a06b786
token_accessor     26599a19-c39e-0712-307b-8fc69fd34d41
token_duration     768h
token_renewable    true
token_policies     [default hiera]
```

Now, change the token in the `hiera.yaml` file under production in the repo:

```
---
version: 5
hierarchy:
  - name: "Hiera-vault lookup"
    lookup_key: hiera_vault
    options:
      confine_to_keys:
        - '^vault_.*'
        - '^.*_password$'
        - '^password.*'
      ssl_verify: false
      address: http://puppet:8200
      token: 4d82fbc8-1e50-ee43-5cbb-38715a06b786
      default_field: value
      mounts:
        generic:
          - secret/puppet/%{::trusted.certname}/

```

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

Now change it...

```
$ VAULT_TOKEN=677b88e3-300c-3a5a-ea2f-72ba70be5516 VAULT_ADDR='http://127.0.0.1:8200' vault write secret/puppet/node1/vault_notify value=gbye_123
Success! Data written to: secret/puppet/common/vault_notify
```

And see the message change:

```
$ puppet agent -t
Info: Using configured environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Retrieving locales
Info: Loading facts
Info: Caching catalog for node1.home
Info: Applying configuration version '1521467005'
Notice: testing vault gbye_123
Notice: /Stage[main]/Profile::Vault_message/Notify[testing vault gbye_123]/message: defined 'message' as 'testing vault gbye_123'
Notice: Applied catalog in 0.14 seconds
[root@node1 vagrant]# exit
```

# Security

This repository is meant as a non-production sandbox setup!
It is not a guide on how to setup a secure Puppet and Vault environment.

In particular this means:

* Auto signing is enabled, every node that connects to the puppetserver is automatically signed.
* Passwords or PSKs are not randomized and easily guessable.
* Vault should be on it's own dedicated node rather than the same server as the puppet master
* Vault is using the file backend rather than Consul, meaning that it's less scalable and has issues with DR if the file mount is lost
* Vault should have ssl_verify set to true, and certificates configured

For a non publicly reachable playground this should be acceptable, and will give you a general picture of how to set this up yourself.

# Help and thanks

This is a heavily modified form of roman-mueller/puppet4-sandbox but focused on demo-ing Hiera and Vault
