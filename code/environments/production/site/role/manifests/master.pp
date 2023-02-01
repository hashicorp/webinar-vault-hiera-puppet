# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# Puppet master role

class role::master {

  include ::profile::base
  include ::profile::master

}
