#!/usr/bin/env bash

set -ux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	for MUTANT in $(find mutants -type f | grep -v manual | sort -r); do
		git apply $MUTANT

		forge test
		echidna . --contract EchidnaTester --config test/config.yaml

		# cleanup
		git checkout .
	done
	cd -
done