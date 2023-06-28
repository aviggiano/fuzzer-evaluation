#!/usr/bin/env bash

set -eux

for protocol in protocols/* ; do
  cd "$protocol"
  forge test
  echidna . --contract EchidnaTester --config test/config.yaml
  cd -
done