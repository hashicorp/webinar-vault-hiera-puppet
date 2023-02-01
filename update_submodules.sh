# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

for d in code/environments/production/modules/**
do
    ( cd "$d" && git pull )
done
