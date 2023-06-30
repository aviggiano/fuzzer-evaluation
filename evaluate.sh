#!/usr/bin/env bash

set -ux

RESULTS="results.txt"
PARAMETERS="parameters.txt"

echo "echidna=$(echidna --version)" > $PARAMETERS
echo "slither=$(slither --version)" >> $PARAMETERS
echo "forge=$(forge --version)" >> $PARAMETERS
echo "solc=$(solc --version | head -2 | tail -1)" >> $PARAMETERS

echo "fuzzer,protocol,seed,mutant,time,result" > $RESULTS

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

			echo "foundry,$PROTOCOL,$SEED,$MUTANT,$TIME,$RESULT" >> $RESULTS

			START=$(date +%s)
			echidna . --contract EchidnaTester --config test/config.yaml
			RESULT=$?
			END=$(date +%s)
			TIME=$(echo "$END - $START" | bc)

			echo "foundry,$PROTOCOL,$SEED,$MUTANT,$TIME,$RESULT" >> $RESULTS

			# cleanup
			git checkout .
		done
		cd -
	done
done