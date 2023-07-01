#!/usr/bin/env bash

set -ux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	forge test
	echidna . --contract EchidnaTester --config test/config.yaml
	cd -
done