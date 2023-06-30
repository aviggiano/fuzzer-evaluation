#!/usr/bin/env bash

set -eux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	mkdir -p mutants

	mkdir -p mutants/slither
	i=0
	for FILE in $(find src -type f -name '*.sol'); do 
		PATCH=$(mktemp)
		slither-mutate $FILE --solc-remaps @openzeppelin/=lib/openzeppelin-contracts/contracts --solc-remaps @uniswap/=src/ > $PATCH
		# ignore files without changes
		exit;
		if [ $(wc -l < $PATCH) -gt 1 ]; then
			# ignore files with more than 1 change
			if [ $(grep '\s./src' $PATCH | awk '{print $NF}' | sort -u | wc -l) -eq 1 ]; then
				i=$((i+1))
				patch < $PATCH || true
				MUTANT=mutants/slither/$(printf "%02d" $i).patch
				git diff > $MUTANT
				git checkout .
				find . -name '*.sol.orig' -exec rm {} \;
				find . -name '*.sol.rej' -exec rm {} \;
			fi;
		fi;
	done

	i=0
	mkdir -p mutants/gambit
	for FILE in $(find src -type f -name '*.sol'); do 
		MUTANT_DIR=$(mktemp -d)
		mkdir -p $MUTANT_DIR
		gambit mutate --filename $FILE --solc-remappings @openzeppelin/=lib/openzeppelin-contracts/contracts/ --solc-remappings @uniswap=src --num-mutants 1 --outdir $MUTANT_DIR
		if [ $(find $MUTANT_DIR -type f -name '*.sol' | wc -l) -gt 0 ]; then
			i=$((i+1))
			MUTANT=mutants/gambit/$(printf "%02d" $i).patch
			mv $(find $MUTANT_DIR -type f -name '*.sol') $FILE
			git diff $FILE > $MUTANT
			git checkout $FILE
		fi
	done

	cd -
done