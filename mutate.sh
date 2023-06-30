#!/usr/bin/env bash

set -eux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	mkdir -p mutants

	mkdir -p mutants/slither
	i=0
	for FILE in $(find src -type f -name '*.sol'); do 
		i=$((i+1))
		MUTANT=mutants/slither/$(printf "%02d" $i).patch
		slither-mutate $FILE --solc-remaps @openzeppelin/=lib/openzeppelin-contracts/contracts --solc-remaps @uniswap/=src/ > $MUTANT
		# ignore files without changes
		if [ $(wc -l < $MUTANT) -eq 1 ]; then
			rm $MUTANT
			i=$((i-1))
		fi;
	done
	cd -
done