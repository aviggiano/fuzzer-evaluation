#!/usr/bin/env bash

set -eux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	mkdir -p mutants

	mkdir -p mutants/slither
	i=0
	for FILE in $(find src -type f -name '*.sol' | grep -v interface); do 
		let i++
		slither-mutate $FILE --solc-remaps @openzeppelin/=lib/openzeppelin-contracts/contracts --solc-remaps @uniswap/=src/ > mutants/slither/$(printf "%02d" $i).patch
	done
	cd -
done