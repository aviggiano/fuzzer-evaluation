#!/usr/bin/env bash

set -ux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	for MUTANT in $(find mutants -type f | grep -v manual | sort -r); do
		# some mutants are git patches, other are plain patch files
		git apply $MUTANT
		apply < $MUTANT

		forge test
		echidna . --contract EchidnaTester --config test/config.yaml

		# cleanup
		git checkout .
		find . -name '*.sol.orig' -exec rm {} \;
		find . -name '*.sol.rej' -exec rm {} \;
	done
	cd -
done