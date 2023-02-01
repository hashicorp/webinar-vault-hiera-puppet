# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

provider "vault" {
  # Set token via VAULT_TOKEN=<token>
  #
  address = "http://127.0.0.1:8200"
}

resource "vault_policy" "hiera_vault" {
  name = "hiera"

  policy = <<EOT
path "secret/puppet/*" {
  capabilities = ["read","list"]
}
EOT
}

resource "vault_policy" "hiera_vault_operator" {
  name = "hiera-operator"

  policy = <<EOT
# view the top level list
path "secret/" {
  capabilities = ["list"]
}

# change puppet entries
path "secret/puppet/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOT
}

resource "vault_generic_secret" "vault_notify" {
  path = "secret/puppet/node1/vault_notify"

  data_json = <<EOT
{
  "value": "Hello World"
}
EOT
}
