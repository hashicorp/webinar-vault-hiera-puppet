#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


if [ ! -f /etc/provisioned ] ; then
  # remove strange manually placed repo file
  /bin/rm -f /etc/yum.repos.d/puppetlabs*

  # install Puppet 6.x release repo
  /bin/yum -y install https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
  if [ $? -ne 0 ] ; then
    echo "Something went wrong installing the repository RPM"
    exit 1
  fi

  # install / update puppet-agent
  /bin/yum -y install puppet-agent
  if [ $? -ne 0 ] ; then
    echo "Something went wrong installing puppet-agent"
    exit 1
  fi

  echo "10.13.37.2 puppet puppet.vm" >> /etc/hosts

  # Update curl and install unzip
  /bin/yum -y install curl unzip

  touch /etc/provisioned

fi

