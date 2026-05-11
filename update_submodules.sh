# Copyright IBM Corp. 2018, 2026

for d in code/environments/production/modules/**
do
    ( cd "$d" && git pull )
done
