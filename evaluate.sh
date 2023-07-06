#!/usr/bin/env bash

set -ux

SEED="$1"
MUTANT="$2"
FUZZER="$3"

TIMEOUT=86400
RESULTS="$(pwd)/results.txt"
PARAMETERS="$(pwd)/parameters.txt"
WORKERS=$(cat /proc/cpuinfo | grep processor | wc -l)
if [ $WORKERS -eq 0 ]; then
	WORKERS=1
fi

echo "instance=$(wget -q -O - http://instance-data/latest/meta-data/instance-type)" > $PARAMETERS
echo "echidna=$(echidna --version)" >> $PARAMETERS
echo "slither=$(slither --version)" >> $PARAMETERS
echo "forge=$(forge --version)" >> $PARAMETERS
echo "solc=$(solc --version | head -2 | tail -1)" >> $PARAMETERS

echo "fuzzer,protocol,seed,mutant,time,result" > $RESULTS

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	for MUTANT_FILE in $(find mutants -type f | sort -r -t'/' -k 3,3 | grep "$MUTANT"); do
		git apply $MUTANT_FILE
		MUTANT=$(echo $MUTANT_FILE | grep -o '[0-9][0-9]')

		if [ $(echo "foundry" | grep "$FUZZER" | wc -l) -gt 0 ]; then
			forge clean
			START=$(date +%s)
			timeout -k 10 $TIMEOUT forge test --fuzz-seed $SEED
			RESULT=$?
			END=$(date +%s)
			TIME=$(echo "$END - $START" | bc)
			echo "foundry,$PROTOCOL,$SEED,$MUTANT,$TIME,$RESULT" >> $RESULTS
		fi

		if [ $(echo "echidna" | grep "$FUZZER" | wc -l) -gt 0 ]; then
			forge clean
			START=$(date +%s)
			timeout -k 10 $TIMEOUT echidna . --contract EchidnaTester --config test/config.yaml --workers $WORKERS --seed $SEED >/dev/null
			RESULT=$?
			END=$(date +%s)
			TIME=$(echo "$END - $START" | bc)
			echo "echidna,$PROTOCOL,$SEED,$MUTANT,$TIME,$RESULT" >> $RESULTS
		fi

		# cleanup
		git checkout .
	done
	cd -
done

sleep 90

sudo shutdown -h now