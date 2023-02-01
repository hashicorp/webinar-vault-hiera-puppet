# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# Puppet vault_message role

class role::vault_message {

  include ::profile::base
  include ::profile::vault_message

}
