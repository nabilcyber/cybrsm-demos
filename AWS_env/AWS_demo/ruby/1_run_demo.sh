#!/bin/bash 

source ../demo.config

sudo mkdir -p /usr/local/lib/summon
sudo cp ./summon-aws.rb /usr/local/lib/summon/
summon -p summon-aws.rb ./echo_secrets.sh
