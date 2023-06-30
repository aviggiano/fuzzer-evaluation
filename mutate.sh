#!/usr/bin/env bash

set -eux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	for FILE in $(find src -type f -name '*.sol'); do 
		slither-mutate $FILE --solc-remaps @openzeppelin/=lib/openzeppelin-contracts/contracts --solc-remaps @uniswap/=src/ > $FILE.patch
	done
	cd -
done