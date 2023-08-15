#!/usr/bin/env bash

set -eux

echo "[$(date)] Start setup"

export WORKDIR=/home/ubuntu

echo "[$(date)] Go to working directory"
cd $WORKDIR

echo "[$(date)] Wait for cloud-init"
cloud-init status --wait

echo "[$(date)] Install OS libraries"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git gcc make python3-pip unzip jq

echo "[$(date)] Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws
rm awscliv2.zip

echo "[$(date)] Install Node.js"
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -

echo "[$(date)] Install yarn"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn

echo "[$(date)] Install solc-select"
sudo pip3 install solc-select

echo "[$(date)] Install latest solidity versions"
solc-select install | tail -n +2 | xargs -I{} solc-select install {}

echo "[$(date)] Install slither"
sudo pip3 install slither-analyzer

echo "[$(date)] Install echidna"
wget https://github.com/crytic/echidna/releases/download/v2.2.0/echidna-2.2.0-Ubuntu-22.04.tar.gz -O echidna.tar.gz
tar -xvkf echidna.tar.gz
sudo mv echidna /usr/bin/
rm echidna.tar.gz

echo "[$(date)] Install foundry"
curl -L https://foundry.paradigm.xyz | bash
export PATH="$PATH:$HOME/.foundry/bin"
foundryup
sudo mv .foundry/bin/* /usr/bin/

echo "[$(date)] Install medusa"
curl -fsSL https://github.com/crytic/medusa/releases/download/v0.1.0/medusa-linux-x64.zip -o medusa.zip
unzip medusa.zip
chmod +x medusa
sudo mv medusa /usr/local/bin

echo "[$(date)] Finish setup"
