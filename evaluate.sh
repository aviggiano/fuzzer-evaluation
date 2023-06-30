#!/usr/bin/env bash

set -ux

RESULTS=$(printf "results_%s_%s_%s_%s.txt", $(echidna --version), $(slither --version), $(forge --version), $(solc --version))
echo "fuzzer,protocol,seed,mutant,time,result" > results.txt

for SEED in $(cat seeds.txt); do
	for PROTOCOL in $(ls protocols); do
		cd protocols/$PROTOCOL
		for MUTANT_FILE in $(find mutants -type f | sort); do
			git apply $MUTANT_FILE
			MUTANT=$(echo $MUTANT_FILE | grep -o '\d\d')

			START=$(date +%s)
			forge test
			RESULT=$?
			END=$(date +%s)
			TIME=$(echo "$END - $START" | bc)

			echo "foundry,$PROTOCOL,$SEED,$MUTANT,$TIME,$RESULT" >> results.txt

			START=$(date +%s)
			echidna . --contract EchidnaTester --config test/config.yaml
			RESULT=$?
			END=$(date +%s)
			TIME=$(echo "$END - $START" | bc)

			echo "foundry,$PROTOCOL,$SEED,$MUTANT,$TIME,$RESULT" >> results.txt

			# cleanup
			git checkout .
		done
		cd -
	done
done