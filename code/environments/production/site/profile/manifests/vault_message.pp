# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# profile to deploy a puppet vault_message

class profile::vault_message {

  $vault_notify = lookup({"name" => "vault_notify", "default_value" => "No Vault Secret Found"})
  notify { "testing vault ${vault_notify}":}

}
