#!/usr/bin/env bash

set -eux

for protocol in protocols/* ; do
  cd "$protocol"
  forge test
  echidna . --contract Echidna --config src/echidna/config.yaml
  cd -
done